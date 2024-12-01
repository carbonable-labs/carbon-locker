
    //use openzeppelin::token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait};
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

    use openzeppelin::token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait};

    #[storage]
    struct Storage {
        wrapped_token: ERC721ABIDispatcher,
    }

    #[embeddable_as(NFTComponentImpl)]
    impl NFTComponent< 
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        > of INFTComponent<ComponentState<TContractState>> {

            fn initialize(
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

        }
}





//fn balance_of(self: @ComponentState<TContractState>, account: ContractAddress) -> u256 {
//  self.wrapped_token.read().balance_of(account)
//}




use starknet::ContractAddress;

#[starknet::contract]
mod NFTCertificate {
    use starknet::ContractAddress;

    use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};

    use carbon_locker::components::certificate::certificate::NFTComponent;

    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::introspection::src5::SRC5Component;

    component!(path: NFTComponent, storage: nft_component, event: NFTComponentEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl NFTComponentImpl = NFTComponent::NFTComponentImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        nft_component: NFTComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        NFTComponentEvent: NFTComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.initialize("Certificate", "CERT", "");
    }
}
