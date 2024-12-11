#[starknet::component]
mod NFTComponent {
    // Starknet imports
    use starknet::{ContractAddress, get_caller_address};

    // Internal imports
    use carbon_locker::components::certificate::interface::INFTComponent;
    use carbon_locker::components::certificate::interface::LOCKER_ROLE;
    use carbon_locker::components::locker::interface::Lock;

    // Roles
    use openzeppelin::access::accesscontrol::interface::IAccessControl;
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin_access::accesscontrol::AccessControlComponent::InternalTrait as AccessControlInternalTrait;

    // SRC5
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};

    // ERC721
    use openzeppelin::token::erc721::{
        ERC721Component, ERC721HooksEmptyImpl, ERC721Component::InternalTrait as ERC721InternalTrait
    };

    mod Errors {
        const INVALID_ROLE: felt252 = 'Only Locker is allowed';
    }

    #[storage]
    struct Storage {//metadatas: Map<u256, Lock>
    }

    #[embeddable_as(NFTComponentImpl)]
    impl NFTComponent<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +IAccessControl<TContractState>,
        impl AccessControl: AccessControlComponent::HasComponent<TContractState>,
    > of INFTComponent<ComponentState<TContractState>> {
        fn mint(
            ref self: ComponentState<TContractState>,
            to: ContractAddress,
            token_id: u256,
            lock_data: Lock
        ) {
            self.assert_only_locker(LOCKER_ROLE);
            let mut erc721_component = get_dep_component_mut!(ref self, ERC721);
            erc721_component.mint(to, token_id);
        }

        fn burn(ref self: ComponentState<TContractState>, token_id: u256) {
            self.assert_only_locker(LOCKER_ROLE);
            let mut erc721_component = get_dep_component_mut!(ref self, ERC721);
            erc721_component.burn(token_id);
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +IAccessControl<TContractState>,
        impl AccessControl: AccessControlComponent::HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            locker_address: ContractAddress,
            token_name: ByteArray,
            token_symbol: ByteArray,
            token_base_uri: ByteArray,
        ) {
            let mut access_control = get_dep_component_mut!(ref self, AccessControl);
            access_control.initializer();
            access_control._grant_role(LOCKER_ROLE, locker_address);

            let mut erc721_component = get_dep_component_mut!(ref self, ERC721);
            erc721_component.initializer(token_name, token_symbol, token_base_uri);
        }

        // Only the Locker address is allowed to mint and burn a token
        fn assert_only_locker(self: @ComponentState<TContractState>, role: felt252) {
            let caller = get_caller_address();
            let has_role = self.get_contract().has_role(role, caller);
            assert(has_role, Errors::INVALID_ROLE);
        }
    }
}
