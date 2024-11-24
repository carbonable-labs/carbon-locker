#[starknet::component]
mod LockerComponent {
    // Core imports
    use core::hash::LegacyHash;

    // Starknet imports

    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};

    // Internal imports
    use carbon_locker::components::locker::interface::ILockerHandler;

    // External imports
    use carbon_v3::components::vintage::interface::{IVintageDispatcher, IVintageDispatcherTrait};
    use carbon_v3::models::carbon_vintage::{CarbonVintage, CarbonVintageType};
    use carbon_v3::contracts::project::{
        IExternalDispatcher as IProjectDispatcher,
        IExternalDispatcherTrait as IProjectDispatcherTrait
    };
    use carbon_v3::components::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};

    // Roles
    use openzeppelin::access::accesscontrol::interface::IAccessControl;

    // ERC20
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    // Constants
    use carbon_v3::contracts::project::Project::OWNER_ROLE;

    #[derive(Copy, Drop, Debug, Hash, starknet::Store, Serde, PartialEq)]
    struct Lock {
        id: u256, // Unique ID of the lock
        user: ContractAddress,
        token_id: u256, // token_id locked, related to vintage
        amount: u256,
        start_time: u256,
        end_time: u256,
        offsettable: bool,
        is_offsetted: bool
    }

    #[storage]
    struct Storage {
        locks: LegacyMap<u256, Lock>, // ID => Lock struct
        // user_locks: LegacyMap<(ContractAddress, u256), u256>, // (User address, index) => Lock ID
        // user_lock_counts: LegacyMap<ContractAddress, u256>, // User address => Number of locks
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
        ProjectSet: ProjectSet
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

    mod Errors {
        const MISSING_ROLE: felt252 = 'Locker: Missing role';
        const VINTAGE_NOT_AUDITED: felt252 = 'Vintage status is not audited';
        const INSUFFICIENT_BALANCE: felt252 = 'Not enough carbon credits';
        const NOT_OFFSETTER: felt252 = 'Caller is not offsetter';
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
                stored_vintage.status == CarbonVintageType::Audited,
                Errors::VINTAGE_NOT_AUDITED
            );

            // Check the user's balance
            let erc1155 = IERC1155Dispatcher { contract_address: project_address };
            let caller_balance = erc1155.balance_of(caller_address, token_id);
            assert(caller_balance >= amount, Errors::INSUFFICIENT_BALANCE);

            // Transfer the tokens from the caller to the LockerComponent, it should approved first
            let project = IProjectDispatcher { contract_address: project_address };
            project.safe_transfer_from(
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
        }

        /// Checks if the lock period has expired.
        fn is_lock_expired(
            self: @ComponentState<TContractState>, lock_id: u256
        ) -> bool {
            let lock = self.locks.read(lock_id);
            let current_time: u256 = get_block_timestamp().into();
            return current_time >= lock.end_time;
        }

        /// Initiates the offsetting of locked credits after the lock period.
        fn offset_credits(ref self: ComponentState<TContractState>, token_id: u256) {}

        /// Retrieves the details of locked credits for a user.
        fn get_locked_credits(
            self: @ComponentState<TContractState>, user: ContractAddress, token_id: u256
        ) -> u256 {
            return 0;
        }

        /// Allows the user to withdraw credits before the lock period ends with a penalty.
        fn early_withdraw(ref self: ComponentState<TContractState>, token_id: u256) {}

        /// Retrieves the contract address of offsetter
        fn get_offsetter_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.assert_only_role(OWNER_ROLE);
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
            self.assert_only_role(OWNER_ROLE);
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
            self.assert_only_role(OWNER_ROLE);
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
            ref self: ComponentState<TContractState>, carbonable_project_address: ContractAddress,
        ) {}

        fn assert_only_role(self: @ComponentState<TContractState>, role: felt252) {
            // [Check] Caller has role
            let caller = get_caller_address();
            let has_role = self.get_contract().has_role(role, caller);
            assert(has_role, Errors::MISSING_ROLE);
        }
    }
}
