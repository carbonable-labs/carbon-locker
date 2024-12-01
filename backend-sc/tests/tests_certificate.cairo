use starknet::{ContractAddress, contract_address_const, get_caller_address};

use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    cheatcodes::events::{EventSpyAssertionsTrait, EventSpyTrait, EventsFilterTrait}
};

use carbon_locker::components::certificate::interface::{
    INFTComponent, INFTComponentDispatcher, INFTComponentDispatcherTrait
};

use carbon_locker::contracts::certificate::NFTCertificate;

use openzeppelin::token::erc721::interface::IERC721;

use openzeppelin::token::erc721::interface::{
    IERC721Dispatcher,
    IERC721DispatcherTrait,
    IERC721Metadata,
    IERC721MetadataDispatcher,
    IERC721MetadataDispatcherTrait
};

fn deploy_nft_certificate() -> ContractAddress {
    let contract = snf::declare("NFTCertificate").expect('Declaration failed');

    let mut calldata: Array<felt252> = array![];
    let (contract_address, _) = contract.deploy(@calldata).expect('Certificate deployment failed');

    contract_address
}

#[test]
fn test_proper_initialization() {
    let certificate_address = deploy_nft_certificate();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };
    let erc721_metadata = IERC721MetadataDispatcher { contract_address: certificate_address };

    let mut balance = erc721.balance_of(user_address);
    assert(balance == 0, 'Balance should be 0');

    let name = erc721_metadata.name();
    assert(name == "Certificate", 'Token name mismatch');
}

#[test]
fn test_mint_function() {
    let certificate_address = deploy_nft_certificate();
    let certificate = INFTComponentDispatcher { contract_address: certificate_address };
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };

    certificate.mint(user_address, 1);
    let mut balance = erc721.balance_of(user_address);
    assert(balance == 1, 'Balance should be 1');
}

#[test]
fn test_burn_function() {
    let certificate_address = deploy_nft_certificate();
    let certificate = INFTComponentDispatcher { contract_address: certificate_address };
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };

    certificate.mint(user_address, 1);
    certificate.burn(1);
    let mut balance = erc721.balance_of(user_address);
    assert(balance == 0, 'Balance should be 0');
}
