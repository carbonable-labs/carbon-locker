#[starknet::component]
mod LockerComponent {
    // Core imports
    use core::hash::LegacyHash;

    // Starknet imports

    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    // Internal imports
    use carbon_locker::components::locker::interface::ILockerHandler;

    // External imports
    use carbon_v3::components::vintage::VintageComponent;

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
        offsettable: bool
    }

    #[storage]
    struct Storage {
        locks: LegacyMap<u256, Lock>, // ID => Lock struct
        user_locks: LegacyMap<ContractAddress, Array<u256>>, // User address => List of his lock ids
        next_lock_id: u256,
        nft_component: ContractAddress, // NFT component address
        offsetter: ContractAddress, // Offsetter component address
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OffsetterSet: OffsetterSet,
        NFTComponentSet: NFTComponentSet
    }

    #[derive(Drop, starknet::Event)]
    struct OffsetterSet {
        offsetter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct NFTComponentSet {
        nft_component: ContractAddress,
    }

    mod Errors {
        const MISSING_ROLE: felt252 = 'Locker: Missing role';
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
        ) {}

        /// Checks if the lock period has expired for a user's locked credits.
        fn is_lock_expired(
            self: @ComponentState<TContractState>, user: ContractAddress, token_id: u256
        ) -> bool {
            return false;
        }

        /// Initiates the offsetting of locked credits after the lock period.
        fn offset_credits(ref self: ComponentState<TContractState>, token_id: u256) {}

        /// Retrieves the details of locked credits for a user.
        fn get_locked_credits(
            self: @ComponentState<TContractState>, user: ContractAddress, token_id: u256
        ) -> (u256, u256) {
            return (0, 0);
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
            self.offsetter.write(address);
            self.emit(OffsetterSet { offsetter: address });
        }

        /// Retrieves the contract address of the NFT component
        fn get_nft_component_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.nft_component.read()
        }

        /// Sets the contract address of the NFT component
        fn set_nft_component_address(
            ref self: ComponentState<TContractState>, address: ContractAddress
        ) {
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
