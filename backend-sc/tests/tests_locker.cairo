// Starknet deps

use starknet::{ContractAddress, contract_address_const, get_caller_address};

// External deps

use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events,
    cheatcodes::events::{EventSpyAssertionsTrait, EventSpyTrait, EventsFilterTrait}
};

// Models

use carbon_v3::models::carbon_vintage::{CarbonVintage, CarbonVintageType};

// Components

use carbon_v3::components::vintage::interface::{
    IVintage, IVintageDispatcher, IVintageDispatcherTrait
};
use carbon_locker::components::locker::interface::{ILockerHandlerDispatcher, ILockerHandlerDispatcherTrait, ILockerHandler};

// Contracts
use carbon_locker::contracts::locker::Locker;


fn deploy_locker() -> ContractAddress {
    let contract = snf::declare("Locker").expect('Declaration failed');
    let mut calldata: Array<felt252> = array![
        contract_address_const::<'CARBONABLE_PROJECT'>().into(), contract_address_const::<'OWNER'>().into()
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
    let token_id: u256= 0;
    let locked_credits = locker.get_locked_credits(user_address, token_id);
    println!("locked_credits: {locked_credits}");
    assert(locked_credits == 0, 'Locked_credits should be 0');
}