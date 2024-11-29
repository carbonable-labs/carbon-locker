use starknet::{ContractAddress, contract_address_const, get_caller_address};

use openzeppelin::token::erc721::interface::IERC721;
//use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};

use openzeppelin::token::erc721::interface::{
    IERC721Dispatcher,
    IERC721DispatcherTrait,
    IERC721Metadata,
    IERC721MetadataDispatcher,
    IERC721MetadataDispatcherTrait
};

use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    cheatcodes::events::{EventSpyAssertionsTrait, EventSpyTrait, EventsFilterTrait}
};

use carbon_locker::components::certificate::interface::{
    INFTComponent, INFTComponentDispatcher, INFTComponentDispatcherTrait
};

use carbon_locker::contracts::certificate::Certificate;

fn deploy_nft_certificate() -> ContractAddress {
    let contract = snf::declare("Certificate").expect('Declaration failed');

    let mut calldata: Array<felt252> = array![];

    let (contract_address, _) = contract.deploy(@calldata).expect('NFT deployment failed');
    contract_address
}

#[test]
fn test_proper_initialization() {
    let certificate_address = deploy_nft_certificate();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    start_cheat_caller_address(certificate_address, user_address);
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };
    let erc721_metadata = IERC721MetadataDispatcher { contract_address: certificate_address };

    let name = erc721_metadata.name();
    assert(name == "Certificate", 'Name should be Certificate');
    let symbol = erc721_metadata.symbol();
    assert(symbol == "CERT", 'Symbol should be CERT');

    let balance = erc721.balance_of(user_address);
    assert(balance == 0, 'Balance should be 0');
}

#[test]
fn test_mint() {
    let certificate_address = deploy_nft_certificate();
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    start_cheat_caller_address(certificate_address, user_address);

    let nft_component = INFTComponentDispatcher { contract_address: certificate_address };
    let nft_id = 1;
    nft_component.mint(user_address, nft_id);

    let balance = erc721.balance_of(user_address);
    assert(balance == 1, 'Balance should be 1');
}
