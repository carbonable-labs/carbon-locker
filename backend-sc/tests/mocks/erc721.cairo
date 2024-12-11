use starknet::ContractAddress;

#[starknet::contract]
mod MockERC721 {
    use starknet::ContractAddress;

    // SRC5
    use openzeppelin_introspection::src5::SRC5Component;
    // ERC721
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    // Access Control - RBA
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    // Certificate NFT Component
    use carbon_locker::components::certificate::certificate::NFTComponent;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: NFTComponent, storage: nft_component, event: NFTComponentEvent);

    // ERC721 Mixin
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    // Access Control
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    // NFT Certificate
    #[abi(embed_v0)]
    impl NFTComponentImpl = NFTComponent::NFTComponentImpl<ContractState>;
    impl NFTComponentInternalImpl = NFTComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        nft_component: NFTComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        NFTComponentEvent: NFTComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, locker_address: ContractAddress) {
        self.nft_component.initializer(locker_address, "Certificate", "CERT", "data:application/json,");
    }
}

