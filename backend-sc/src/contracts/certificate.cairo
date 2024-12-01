use starknet::ContractAddress;

#[starknet::contract]
mod NFTCertificate {
    use starknet::ContractAddress;

    use carbon_locker::components::certificate::certificate::NFTComponent;

    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::introspection::src5::SRC5Component;

    component!(path: NFTComponent, storage: nft_component, event: NFTComponentEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
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
        self.initializer("Certificate", "CERT", "");
    }
}
