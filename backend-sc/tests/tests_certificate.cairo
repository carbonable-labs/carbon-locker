// Starknet deps

use starknet::{ContractAddress, contract_address_const, get_caller_address, get_block_timestamp};

// External deps

use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpy, spy_events, EventSpyTrait,
    EventSpyAssertionsTrait, start_cheat_caller_address, stop_cheat_caller_address
};

// Components

use carbon_locker::components::certificate::interface::{
    INFTComponent, INFTComponentDispatcher, INFTComponentDispatcherTrait
};

// Components

use openzeppelin::token::erc721::interface::{
    IERC721Dispatcher, IERC721DispatcherTrait, IERC721Metadata, IERC721MetadataDispatcher,
    IERC721MetadataDispatcherTrait
};

// Contracts
use super::mocks::erc721::ERC721;

fn deploy_certificate() -> ContractAddress {
    let contract_class = snf::declare("ERC721").expect('Declaration failed').contract_class();

    let mut calldata: Array<felt252> = array![];
    let deploy_result = contract_class.deploy(@calldata);

    let (contract_address, _) = deploy_result.expect('Certificate deployment failed');

    contract_address
}

#[test]
fn test_proper_initialization() {
    let certificate_address = deploy_certificate();
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
    let certificate_address = deploy_certificate();
    let certificate = INFTComponentDispatcher { contract_address: certificate_address };
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };

    certificate.mint(user_address, 1);
    let mut balance = erc721.balance_of(user_address);
    assert(balance == 1, 'Balance should be 1');
}

#[test]
fn test_burn_function() {
    let certificate_address = deploy_certificate();
    let certificate = INFTComponentDispatcher { contract_address: certificate_address };
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };

    certificate.mint(user_address, 1);
    certificate.burn(1);
    let mut balance = erc721.balance_of(user_address);
    assert(balance == 0, 'Balance should be 0');
}
