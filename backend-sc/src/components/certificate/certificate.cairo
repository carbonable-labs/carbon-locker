#[starknet::component]
mod NFTComponent {
    use starknet::ContractAddress;

    use carbon_locker::components::certificate::interface::INFTComponent;

    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{
        ERC721Component,
        ERC721Component::ERC721Impl,
        ERC721Component::InternalTrait,
    };

    #[storage]
    struct Storage {}

    #[embeddable_as(NFTComponentImpl)]
    impl NFTComponent< 
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        > of INFTComponent<ComponentState<TContractState>> {
            // internal
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
                erc721._mint(to, token_id);
            }

            fn burn(ref self: ComponentState<TContractState>, token_id: u256) {
                let mut erc721 = get_dep_component_mut!(ref self, ERC721);
                erc721._burn(token_id);
            }
        }
}
