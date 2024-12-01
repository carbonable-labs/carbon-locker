#[starknet::component]
mod LockerComponent {
    // Core imports
    use core::hash::LegacyHash;

    // Starknet imports

    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};

    use core::starknet::storage_access;
    use core::array::ArrayTrait;
    use starknet::storage::{
        Map, Vec, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, VecTrait,
        MutableVecTrait
    };

    // Internal imports
    use carbon_locker::components::locker::interface::{ILockerHandler, Lock};

    // External imports
    use carbon_v3::components::vintage::interface::{IVintageDispatcher, IVintageDispatcherTrait};
    use carbon_v3::models::carbon_vintage::{CarbonVintage, CarbonVintageType};
    use carbon_v3::contracts::project::{
        IExternalDispatcher as IProjectDispatcher,
        IExternalDispatcherTrait as IProjectDispatcherTrait
    };
    use carbon_v3::components::offsetter::interface::{
        IOffsetHandlerDispatcher, IOffsetHandlerDispatcherTrait
    };
    use carbon_v3::components::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};

    // Roles
    use openzeppelin::access::accesscontrol::interface::IAccessControl;

    // ERC20
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    // Constants
    use carbon_v3::contracts::project::Project::OWNER_ROLE;

    #[storage]
    struct Storage {
        locks: Map<u256, Lock>, // ID => Lock struct
        specific_video_course_uri_with_identifier: Map::<u256, Vec<felt252>>,
        user_allocs: Map::<ContractAddress, Vec<u256>>, // (User address, index) => Lock ID
        locker_id: u256,
        nft_component: ContractAddress, // NFT component address
        offsetter: ContractAddress, // Offsetter component address
        project: ContractAddress, // Project address of the carbon credits
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OffsetterSet: OffsetterSet,
        NFTComponentSet: NFTComponentSet,
        ProjectSet: ProjectSet,
        LockCreated: LockCreated,
        LockOffsetted: LockOffsetted,
    }

    #[derive(Drop, starknet::Event)]
    pub struct OffsetterSet {
        pub offsetter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct NFTComponentSet {
        pub nft_component: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProjectSet {
        pub project: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct LockCreated {
        lock_id: u256,
        user: ContractAddress,
        token_id: u256,
        amount: u256,
        start_time: u256,
        end_time: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct LockOffsetted {
        lock_id: u256,
        user: ContractAddress,
        token_id: u256,
        amount: u256,
    }

    mod Errors {
        const MISSING_ROLE: felt252 = 'Locker: Missing role';
        const VINTAGE_NOT_AUDITED: felt252 = 'Vintage status is not audited';
        const INSUFFICIENT_BALANCE: felt252 = 'Not enough carbon credits';
        const NOT_OFFSETTER: felt252 = 'Caller is not offsetter';
        const NOT_OFFSETTABLE: felt252 = 'Lock not offsettable';
        const ZERO_ADDRESS: felt252 = 'Address is invalid';
    }

    #[embeddable_as(LockerHandlerImpl)]
    impl LockerHandler<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        +IAccessControl<TContractState>
    > of ILockerHandler<ComponentState<TContractState>> {
        /// Lock carbon credits, it should have the "Audited" status
        fn lock_credits(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            amount: u256,
            lock_duration: u256
        ) {
            let caller_address: ContractAddress = get_caller_address();
            let project_address: ContractAddress = self.get_project_address();

            // Check that the vintage has the "Audited" status
            let vintages = IVintageDispatcher { contract_address: project_address };
            let stored_vintage: CarbonVintage = vintages.get_carbon_vintage(token_id);
            assert(
                stored_vintage.status == CarbonVintageType::Audited, Errors::VINTAGE_NOT_AUDITED
            );

            // Check the user's balance
            let erc1155 = IERC1155Dispatcher { contract_address: project_address };
            let caller_balance = erc1155.balance_of(caller_address, token_id);
            assert(caller_balance >= amount, Errors::INSUFFICIENT_BALANCE);

            // Transfer the tokens from the caller to the LockerComponent, it should approved first
            let project = IProjectDispatcher { contract_address: project_address };
            project
                .safe_transfer_from(
                    caller_address, get_contract_address(), token_id, amount, array![].span()
                );

            // Create a new lock
            let locker_id: u256 = self.locker_id.read();
            self.locker_id.write(locker_id + 1);

            let start_time: u256 = get_block_timestamp().into();
            let end_time: u256 = start_time + lock_duration;

            let new_lock = Lock {
                id: locker_id,
                user: caller_address,
                token_id: token_id,
                amount: amount,
                start_time: start_time,
                end_time: end_time,
                offsettable: false,
                is_offsetted: false,
            };
            self.locks.write(locker_id, new_lock);
            let current_user_locks = self.user_allocs.entry(caller_address);
            current_user_locks.append().write(locker_id);
        }

        /// Checks if the lock period has expired.
        fn is_lock_expired(self: @ComponentState<TContractState>, lock_id: u256) -> bool {
            let lock = self.locks.read(lock_id);
            let current_time: u256 = get_block_timestamp().into();
            return current_time >= lock.end_time;
        }

        /// Checks if the lock is offsettable (locking expired and not yet offsetted).
        fn is_lock_offsettable(self: @ComponentState<TContractState>, lock_id: u256) -> bool {
            let lock = self.locks.read(lock_id);
            let current_time: u256 = get_block_timestamp().into();
            return current_time >= lock.end_time && !lock.is_offsetted;
        }

        /// Initiates the offsetting of locked credits after the lock period.
        fn offset_credits(ref self: ComponentState<TContractState>, lock_id: u256) {
            // let caller_address: ContractAddress = get_caller_address();
            let is_offsettable: bool = self.is_lock_offsettable(lock_id);
            assert(is_offsettable, Errors::NOT_OFFSETTABLE);
            let lock: Lock = self.locks.read(lock_id);
            self._offset_credits(lock);
        }

        /// Returns a list of Lock of a user
        fn get_user_locks(
            self: @ComponentState<TContractState>, user: ContractAddress
        ) -> Span<Lock> {
            let current_user_locks = self.user_allocs.entry(user);
            let mut array_locks: Array<Lock> = array![];
            let len = current_user_locks.len();
            let mut i: u64 = 0;
            loop {
                if i >= len {
                    break;
                }
                if let Option::Some(element) = current_user_locks.get(i) {
                    let index = element.read();
                    let lock: Lock = self.locks.read(index);
                    array_locks.append(lock);
                }
                i += 1;
            };
            array_locks.span()
        }
        /// Retrieves the details of a Lock.
        fn get_lock(self: @ComponentState<TContractState>, lock_id: u256) -> Lock {
            self.locks.read(lock_id)
        }

        /// Allows the user to withdraw credits before the lock period ends with a penalty.
        fn early_withdraw(ref self: ComponentState<TContractState>, token_id: u256) {}

        /// Retrieves the contract address of offsetter
        fn get_offsetter_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.offsetter.read()
        }


        /// Sets the contract address of offsetter
        fn set_offsetter_address(
            ref self: ComponentState<TContractState>, address: ContractAddress
        ) {
            self.assert_only_role(OWNER_ROLE);
            self.offsetter.write(address);
            self.emit(OffsetterSet { offsetter: address });
        }

        /// Retrieves the contract address of project
        fn get_project_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.project.read()
        }

        /// Sets the contract address of project
        fn set_project_address(ref self: ComponentState<TContractState>, address: ContractAddress) {
            self.assert_only_role(OWNER_ROLE);
            self.project.write(address);
            self.emit(ProjectSet { project: address });
        }

        /// Retrieves the contract address of the NFT component
        fn get_nft_component_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.nft_component.read()
        }

        /// Sets the contract address of the NFT component
        fn set_nft_component_address(
            ref self: ComponentState<TContractState>, address: ContractAddress
        ) {
            self.assert_only_role(OWNER_ROLE);
            self.nft_component.write(address);
            self.emit(NFTComponentSet { nft_component: address });
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        +IAccessControl<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            carbonable_project_address: ContractAddress,
            offsetter_address: ContractAddress,
        ) {
            assert(carbonable_project_address.into() != 0, Errors::ZERO_ADDRESS);
            assert(carbonable_project_address.into() != 0, Errors::ZERO_ADDRESS);
            assert(offsetter_address.into() != 0, Errors::ZERO_ADDRESS);
            self.project.write(carbonable_project_address);
            self.offsetter.write(offsetter_address);
        }

        fn assert_only_role(self: @ComponentState<TContractState>, role: felt252) {
            // [Check] Caller has role
            let caller = get_caller_address();
            let has_role = self.get_contract().has_role(role, caller);
            assert(has_role, Errors::MISSING_ROLE);
        }

        fn _offset_credits(ref self: ComponentState<TContractState>, lock: Lock) {
            // Burn the credits
            let offsetter_address: ContractAddress = self.offsetter.read();
            let offsetter = IOffsetHandlerDispatcher { contract_address: offsetter_address };

            // The LockerComponent must call the offsetter who has the OFFSETTER role
            let token_id = lock.token_id;
            let amount = lock.amount;
            offsetter.deposit_vintage(token_id, amount);

            // Update the lock to set is_offsetted = true
            let mut updated_lock = lock;
            updated_lock.is_offsetted = true;
            self.locks.write(lock.id, updated_lock);

            // Emit event
            self
                .emit(
                    Event::LockOffsetted(
                        LockOffsetted {
                            lock_id: lock.id,
                            user: lock.user,
                            token_id: lock.token_id,
                            amount: lock.amount,
                        }
                    )
                );
        }
    }
}
