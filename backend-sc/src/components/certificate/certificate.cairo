#[starknet::component]
mod NFTComponent {
    // Starknet imports

    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    // Internal imports
    use carbon_locker::components::certificate::interface::INFTComponent;

    // SRC5
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    // use openzeppelin::introspection::src5::SRC5Component::{SRC5, SRC5Camel};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};

    // ERC 721
    use openzeppelin::token::erc721::interface::IERC721;
    use openzeppelin::token::erc721::{
        ERC721Component, ERC721HooksEmptyImpl, ERC721Component::InternalTrait as ERC721InternalTrait
    };

    #[storage]
    struct Storage {}

    #[embeddable_as(NFTComponentImpl)]
    impl NFTComponent<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of INFTComponent<ComponentState<TContractState>> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            name: ByteArray,
            symbol: ByteArray,
            base_uri: ByteArray
        ) {
            let mut erc721_comp = get_dep_component_mut!(ref self, ERC721);
            erc721_comp.initializer(name, symbol, base_uri);
        }

        fn mint(ref self: ComponentState<TContractState>, to: ContractAddress, token_id: u256) {
            let mut erc721 = get_dep_component_mut!(ref self, ERC721);
            erc721.mint(to, token_id);
        }

        fn burn(ref self: ComponentState<TContractState>, token_id: u256) {
            let mut erc721 = get_dep_component_mut!(ref self, ERC721);
            erc721.burn(token_id);
        }
    }
}
