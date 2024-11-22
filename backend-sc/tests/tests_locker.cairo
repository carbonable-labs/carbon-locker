// Starknet deps

use starknet::{ContractAddress, contract_address_const, get_caller_address};

// External deps

use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    cheatcodes::events::{EventSpyAssertionsTrait, EventSpyTrait, EventsFilterTrait}
};

// Models

use carbon_v3::models::carbon_vintage::{CarbonVintage, CarbonVintageType};

// Components

use carbon_v3::components::vintage::interface::{
    IVintage, IVintageDispatcher, IVintageDispatcherTrait
};
use carbon_locker::components::locker::interface::{
    ILockerHandlerDispatcher, ILockerHandlerDispatcherTrait, ILockerHandler
};

use carbon_locker::components::locker::locker_handler::LockerComponent;

// Contracts
use carbon_locker::contracts::locker::Locker;


fn deploy_locker() -> ContractAddress {
    let contract = snf::declare("Locker").expect('Declaration failed');
    let mut calldata: Array<felt252> = array![
        contract_address_const::<'CARBONABLE_PROJECT'>().into(),
        contract_address_const::<'OWNER'>().into()
    ];
    let (contract_address, _) = contract.deploy(@calldata).expect('Locker deployment failed');

    contract_address
}


/// Example of a test, shouldn't be used to test the validity of get_locked_credits
#[test]
fn test_locker_example() {
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let locker_address = deploy_locker();
    let address_felt: felt252 = locker_address.into();
    println!("Locker address: {}", address_felt);

    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    start_cheat_caller_address(locker_address, user_address);
    let token_id: u256 = 0;
    let locked_credits = locker.get_locked_credits(user_address, token_id);
    println!("locked_credits: {locked_credits}");
    assert(locked_credits == 0, 'Locked_credits should be 0');
}

/// Tests the get_offsetter_address and set_offsetter_address functions
#[test]
fn test_locker_offsetter() {
    let address0: ContractAddress =
        0x2d55d6f311413945595788818d4e89e151360a2c2c6b5270d5d0ed16475505f
        .try_into()
        .unwrap();

    let admin_address: ContractAddress = contract_address_const::<'OWNER'>();

    let locker_address = deploy_locker();
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    let mut spy = spy_events();
    start_cheat_caller_address(locker_address, admin_address);

    let zero_address = locker.get_offsetter_address();
    let zero_address_felt: felt252 = zero_address.into();
    assert(zero_address_felt == 0, 'Offset address should be 0');

    locker.set_offsetter_address(address0);

    spy
        .assert_emitted(
            @array![
                (
                    locker_address,
                    LockerComponent::Event::OffsetterSet(
                        LockerComponent::OffsetterSet { offsetter: address0 }
                    )
                )
            ]
        );

    let offsetter_address = locker.get_offsetter_address();
    assert(offsetter_address == address0, 'Unexpected offsetter address');
}

/// Tests the get_nft_component_address and set_nft_component_address functions
#[test]
fn test_locker_nft_component() {
    let address0: ContractAddress =
        0x2d55d6f311413945595788818d4e89e151360a2c2c6b5270d5d0ed16475505f
        .try_into()
        .unwrap();

    let admin_address: ContractAddress = contract_address_const::<'OWNER'>();

    let locker_address = deploy_locker();
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    let mut spy = spy_events();
    start_cheat_caller_address(locker_address, admin_address);

    let zero_address = locker.get_nft_component_address();
    let zero_address_felt: felt252 = zero_address.into();
    assert(zero_address_felt == 0, 'Offset address should be 0');

    locker.set_nft_component_address(address0);

    spy
        .assert_emitted(
            @array![
                (
                    locker_address,
                    LockerComponent::Event::NFTComponentSet(
                        LockerComponent::NFTComponentSet { nft_component: address0 }
                    )
                )
            ]
        );

    let nft_component_address = locker.get_nft_component_address();
    assert(nft_component_address == address0, 'Unexpected offsetter address');
}

/// Tests if get_offsetter_address can be called by owner only
#[test]
#[should_panic(expected: 'Locker: Missing role')]
fn test_admin_get_offsetter_address() {
    let locker_address = deploy_locker();
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    let _offsetter_address = locker.get_offsetter_address();
}

/// Tests if set_offsetter_address can be called by owner only
#[test]
#[should_panic(expected: 'Locker: Missing role')]
fn test_admin_set_offsetter_address() {
    let address0: ContractAddress =
        0x2d55d6f311413945595788818d4e89e151360a2c2c6b5270d5d0ed16475505f
        .try_into()
        .unwrap();
    let locker_address = deploy_locker();
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    locker.set_offsetter_address(address0);
}

/// Tests if get_nft_component_address can be called by owner only
#[test]
#[should_panic(expected: 'Locker: Missing role')]
fn test_admin_get_nft_component_address() {
    let locker_address = deploy_locker();
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    let _nft_component_address = locker.get_nft_component_address();
}

/// Tests if set_nft_component_address can be called by owner only
#[test]
#[should_panic(expected: 'Locker: Missing role')]
fn test_admin_set_nft_component_address() {
    let address0: ContractAddress =
        0x2d55d6f311413945595788818d4e89e151360a2c2c6b5270d5d0ed16475505f
        .try_into()
        .unwrap();
    let locker_address = deploy_locker();
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    locker.set_nft_component_address(address0);
}
