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
    use carbon_locker::components::locker::interface::{ILockerHandler, Lock, PENALTY_SCALING_FACTOR};

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
        user_allocs: Map::<ContractAddress, Vec<u256>>, // (User address, index) => Lock ID
        locker_id: u256,
        nft_component: ContractAddress, // NFT component address
        offsetter: ContractAddress, // Offsetter component address
        project: ContractAddress, // Project address of the carbon credits
        penalty_multiplier: u64, // Multiplier for penalty calculations (e.g., 500 for 5%)
        penalty_recipient: ContractAddress, // Recipient address for penalties (e.g., NGO)
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OffsetterSet: OffsetterSet,
        NFTComponentSet: NFTComponentSet,
        ProjectSet: ProjectSet,
        LockCreated: LockCreated,
        LockOffsetted: LockOffsetted,
        PenaltyConfigSet: PenaltyConfigSet,
        LockTerminatedWithPenalty: LockTerminatedWithPenalty,
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

    #[derive(Drop, starknet::Event)]
    pub struct PenaltyConfigSet {
        pub penalty_multiplier: u64,
        pub penalty_recipient: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct LockTerminatedWithPenalty {
        pub lock_id: u256,
        pub user: ContractAddress,
        pub withdrawn_amount: u256,
        pub penalty_amount: u256,
        pub recipient: ContractAddress,
    }

    mod Errors {
        const MISSING_ROLE: felt252 = 'Locker: Missing role';
        const VINTAGE_NOT_AUDITED: felt252 = 'Vintage status is not audited';
        const INSUFFICIENT_BALANCE: felt252 = 'Not enough carbon credits';
        const NOT_OFFSETTER: felt252 = 'Caller is not offsetter';
        const NOT_OFFSETTABLE: felt252 = 'Lock not offsettable';
        const ZERO_ADDRESS: felt252 = 'Address is invalid';
        const INVALID_WITHDRAW_AMOUNT: felt252 = 'Withdraw exceeds locked amount';
        const TERMINATE_NOT_ALLOWED: felt252 = 'Terminate not allowed';
        const INVALID_PENALTY_MULTIPLIER: felt252 = 'Invalid penalty multiplier';
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
            lock_duration: u64
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

            // Transfer the tokens from the caller to the LockerComponent, it should be approved first
            let project = IProjectDispatcher { contract_address: project_address };
            project
                .safe_transfer_from(
                    caller_address, get_contract_address(), token_id, amount, array![].span()
                );

            // Create a new lock
            let locker_id: u256 = self.locker_id.read();
            self.locker_id.write(locker_id + 1);

            let start_time: u64 = get_block_timestamp().into();
            let end_time: u64 = start_time + lock_duration;

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
            let current_time: u64 = get_block_timestamp().into();
            return current_time >= lock.end_time;
        }

        /// Checks if the lock is offsettable (locking expired and not yet offsetted).
        fn is_lock_offsettable(self: @ComponentState<TContractState>, lock_id: u256) -> bool {
            let lock = self.locks.read(lock_id);
            let current_time: u64 = get_block_timestamp().into();
            return current_time >= lock.end_time && !lock.is_offsetted;
        }

        /// Initiates the offsetting of locked credits after the lock period.
        fn offset_credits(ref self: ComponentState<TContractState>, lock_id: u256) {
            let is_offsettable: bool = self.is_lock_offsettable(lock_id);
            assert(is_offsettable, Errors::NOT_OFFSETTABLE);
            let lock: Lock = self.locks.read(lock_id);
            self._offset_credits(lock);
        }

        /// Returns a list of Locks of a user
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
        fn early_withdraw(ref self: ComponentState<TContractState>, token_id: u256) {
            // Implementation can be similar to terminate_lock_with_penalty if needed
            // Placeholder for future functionality
        }

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

        /// Terminates a lock with a penalty for early withdrawal.
        fn terminate_lock_with_penalty(
            ref self: ComponentState<TContractState>,
            lock_id: u256,
            withdraw_amount: u256
        ) {
            let caller_address: ContractAddress = get_caller_address();
            let lock: Lock = self.locks.read(lock_id);
            assert(lock.user == caller_address, Errors::TERMINATE_NOT_ALLOWED);
            let vintages = IVintageDispatcher { contract_address: self.project.read() };
            let stored_vintage: CarbonVintage = vintages.get_carbon_vintage(lock.token_id);
            assert(
                stored_vintage.status == CarbonVintageType::Audited,
                Errors::VINTAGE_NOT_AUDITED
            );
            assert(withdraw_amount > 0, Errors::INVALID_WITHDRAW_AMOUNT);
            assert(withdraw_amount <= lock.amount, Errors::INVALID_WITHDRAW_AMOUNT);
            let current_time: u64 = get_block_timestamp().into();
            let remaining_time: u64 = if current_time >= lock.end_time {
                0
            } else {
                lock.end_time - current_time
            };
            let total_lock_time: u64 = lock.end_time - lock.start_time;
            let penalty_amount: u256 = withdraw_amount * self.penalty_multiplier.read().into();
            let penalty_amount: u256 = (penalty_amount* remaining_time.into() / (total_lock_time.into() * PENALTY_SCALING_FACTOR));

            
            let net_withdraw_amount: u256 = withdraw_amount - penalty_amount;

            let erc1155 = IERC1155Dispatcher { contract_address: self.project.read() };
            erc1155.safe_transfer_from(
                get_contract_address(),
                caller_address,
                lock.token_id,
                net_withdraw_amount,
                array![].span()
            );
            let offsetter = IOffsetHandlerDispatcher { contract_address: self.offsetter.read() };
            offsetter.deposit_vintage(lock.token_id, penalty_amount);

            let new_amount = lock.amount - withdraw_amount;
            let updated_lock = Lock {
                amount: new_amount,
                ..lock
            };
            self.locks.write(lock_id, updated_lock);
            self.emit(
                LockTerminatedWithPenalty {
                    lock_id: lock_id,
                    user: caller_address,
                    withdrawn_amount: net_withdraw_amount,
                    penalty_amount: penalty_amount,
                    recipient: self.penalty_recipient.read(),
                }
            );
        }

        fn set_penalty_config(
            ref self: ComponentState<TContractState>,
            penalty_multiplier: u64,
            penalty_recipient: ContractAddress
        ) {
            self.assert_only_role(OWNER_ROLE);
            // Validate the penalty multiplier (e.g., between 0 and PENALTY_SCALING_FACTOR)
            assert(penalty_multiplier.into() <= PENALTY_SCALING_FACTOR, Errors::INVALID_PENALTY_MULTIPLIER);
            assert(penalty_recipient.into() != 0, Errors::ZERO_ADDRESS);

            self.penalty_multiplier.write(penalty_multiplier);
            self.penalty_recipient.write(penalty_recipient);
            self.emit(PenaltyConfigSet {
                penalty_multiplier: penalty_multiplier,
                penalty_recipient: penalty_recipient,
            });
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
            assert(offsetter_address.into() != 0, Errors::ZERO_ADDRESS);
            self.project.write(carbonable_project_address);
            self.offsetter.write(offsetter_address);
            self.penalty_multiplier.write(500); // 5% penalty by default
            self.penalty_recipient.write(
                0x0000000000000000000000000000000000000000.try_into().unwrap() //  todo
            );
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
