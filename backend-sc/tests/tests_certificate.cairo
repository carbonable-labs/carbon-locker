// Starknet deps

use starknet::{ContractAddress, contract_address_const, get_caller_address, get_block_timestamp};

// External deps

use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    start_cheat_block_timestamp_global,
    cheatcodes::events::{EventSpyAssertionsTrait, EventSpyTrait, EventsFilterTrait}
};

// ERC721 Components

use openzeppelin::token::erc721::interface::{
    IERC721Dispatcher, IERC721DispatcherTrait,
    IERC721MetadataDispatcher, IERC721MetadataDispatcherTrait
};

// Internal interfaces
use carbon_locker::components::certificate::interface::{
    INFTComponentDispatcher, INFTComponentDispatcherTrait
};
use carbon_locker::components::locker::interface::Lock;

// Contracts
use super::mocks::erc721::MockERC721;

// Utils for testing purposes
use super::tests_utils::{deploy_all};

fn generate_lock_data() -> Lock {
    Lock {
        id: 1_u256,
        user: contract_address_const::<'USER'>(),
        token_id: 1_u256,
        amount: 1000_u256,
        start_time: get_block_timestamp(),
        end_time: get_block_timestamp() + 1000_u64,
        offsettable: false,
        is_offsetted: false
    }
}

/// Test the intializer function
#[test]
fn test_certificate_initializer() {
    let (_, _, _, _, _, certificate_address) = deploy_all();
    let erc721_metadata = IERC721MetadataDispatcher { contract_address: certificate_address };

    let name = erc721_metadata.name();
    assert(name == "Certificate", 'Token name mismatch');

    let symbol = erc721_metadata.symbol();
    assert(symbol == "CERT", 'Token symbol mismatch');
}

#[test]
fn test_mint() {
    let (_, locker_address, _, _, _, certificate_address) = deploy_all();
    let certificate = INFTComponentDispatcher { contract_address: certificate_address };

    // Call with locker permissions
    start_cheat_caller_address(certificate_address, locker_address);

    // Mint the token
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let token_id: u256 = 1;
    let lock_data = generate_lock_data();
    certificate.mint(user_address, token_id, lock_data);

    // Check the user_address balance
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };
    let balance = erc721.balance_of(user_address);
    assert(balance == 1, 'Balance should be 1');
}

#[test]
#[should_panic(expected: 'Only Locker is allowed')]
fn test_unauthorized_caller_mint() {
    let (_, _, _, _, _, certificate_address) = deploy_all();
    let certificate = INFTComponentDispatcher { contract_address: certificate_address };

    // Call with user_address permissions
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    start_cheat_caller_address(certificate_address, user_address);

    // Mint the token
    let token_id: u256 = 1;
    let lock_data = generate_lock_data();
    certificate.mint(user_address, token_id, lock_data);
    stop_cheat_caller_address(certificate_address);
}

#[test]
fn test_burn() {
    let (_, locker_address, _, _, _, certificate_address) = deploy_all();
    let certificate = INFTComponentDispatcher { contract_address: certificate_address };

    // Call with locker permissions
    start_cheat_caller_address(certificate_address, locker_address);

    // Mint the token
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let token_id: u256 = 1;
    let lock_data = generate_lock_data();
    certificate.mint(user_address, token_id, lock_data);

    // Burn the token
    certificate.burn(token_id);

    // Check the user_address balance
    let erc721 = IERC721Dispatcher { contract_address: certificate_address };
    let balance = erc721.balance_of(user_address);
    assert(balance == 0, 'Balance should be 0');
}

#[test]
#[should_panic(expected: 'Only Locker is allowed')]
fn test_unauthorized_burn() {
    let (_, locker_address, _, _, _, certificate_address) = deploy_all();
    let certificate = INFTComponentDispatcher { contract_address: certificate_address };

    // Call with locker permissions
    start_cheat_caller_address(certificate_address, locker_address);

    // Mint the token
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let token_id: u256 = 1;
    let lock_data = generate_lock_data();
    certificate.mint(user_address, token_id, lock_data);

    // Call with user_address permission
    start_cheat_caller_address(certificate_address, user_address);

    // Burn the token
    certificate.burn(token_id);
}
