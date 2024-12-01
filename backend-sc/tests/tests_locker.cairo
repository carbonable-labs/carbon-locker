// Starknet deps

use starknet::{ContractAddress, contract_address_const, get_caller_address, get_block_timestamp};

// External deps

use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    start_cheat_block_timestamp_global,
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
use carbon_v3::contracts::project::{
    Project, IExternalDispatcher as IProjectDispatcher,
    IExternalDispatcherTrait as IProjectDispatcherTrait
};

use carbon_locker::components::locker::locker_handler::LockerComponent;
use carbon_locker::components::locker::interface::PENALTY_SCALING_FACTOR;

// Contracts
use carbon_locker::contracts::locker::Locker;

// Utils for testing purposes

use super::tests_utils::{
    deploy_project, default_setup_and_deploy, deploy_minter, deploy_locker, deploy_all, buy_utils
};

/// Tests the get_offsetter_address and set_offsetter_address functions
#[test]
fn test_locker_offsetter() {
    let (_, locker_address, _, _, _) = deploy_all();

    let admin_address: ContractAddress = contract_address_const::<'OWNER'>();

    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    let mut spy = spy_events();
    start_cheat_caller_address(locker_address, admin_address);

    let address0: ContractAddress =
        0x2d55d6f311413945595788818d4e89e151360a2c2c6b5270d5d0ed16475505f
        .try_into()
        .unwrap();
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
    let (_, locker_address, _, _, _) = deploy_all();
    let admin_address: ContractAddress = contract_address_const::<'OWNER'>();

    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    let mut spy = spy_events();
    start_cheat_caller_address(locker_address, admin_address);

    let address0: ContractAddress =
        0x2d55d6f311413945595788818d4e89e151360a2c2c6b5270d5d0ed16475505f
        .try_into()
        .unwrap();
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

/// Tests if set_offsetter_address can be called by owner only
#[test]
#[should_panic(expected: 'Locker: Missing role')]
fn test_admin_set_offsetter_address() {
    let (_, locker_address, _, _, _) = deploy_all();
    let address0: ContractAddress =
        0x2d55d6f311413945595788818d4e89e151360a2c2c6b5270d5d0ed16475505f
        .try_into()
        .unwrap();
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    locker.set_offsetter_address(address0);
}

/// Tests if set_nft_component_address can be called by owner only
#[test]
#[should_panic(expected: 'Locker: Missing role')]
fn test_admin_set_nft_component_address() {
    let (_, locker_address, _, _, _) = deploy_all();
    let address0: ContractAddress =
        0x2d55d6f311413945595788818d4e89e151360a2c2c6b5270d5d0ed16475505f
        .try_into()
        .unwrap();
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };
    locker.set_nft_component_address(address0);
}


#[test]
fn test_locker__lock_credits() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let (project_address, locker_address, _, minter_address, _) = deploy_all();

    // Grant necessary roles
    let project = IProjectDispatcher { contract_address: project_address };

    start_cheat_caller_address(project_address, owner_address);
    project.grant_minter_role(minter_address);
    project.grant_offsetter_role(locker_address);
    stop_cheat_caller_address(project_address);

    // Mint tokens to the user
    let vintages = IVintageDispatcher { contract_address: project_address };
    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint = initial_total_supply / 10; // 10% of the total supply

    buy_utils(owner_address, user_address, minter_address, cc_to_mint);
    let token_id: u256 = 1;
    let balance = project.balance_of(user_address, token_id);

    // Set the vintage status to "Audited"
    start_cheat_caller_address(project_address, owner_address);
    vintages.update_vintage_status(token_id, CarbonVintageType::Audited.into());
    stop_cheat_caller_address(project_address);

    // Approve the locker contract to transfer the tokens
    start_cheat_caller_address(project_address, user_address);
    project.set_approval_for_all(locker_address, true);
    stop_cheat_caller_address(project_address);

    // Now, call lock_credits
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };

    start_cheat_caller_address(locker_address, user_address);
    start_cheat_caller_address(project_address, user_address);

    let amount_to_lock = balance;
    let lock_duration: u64 = 1000; // Some duration
    locker.lock_credits(token_id, amount_to_lock, lock_duration);

    // Check that the lock is created
    let lock_id: u256 = 0;

    let lock = locker.get_lock(lock_id);

    // Check that the lock has the expected values
    assert(lock.id == lock_id, 'Lock ID mismatch');
    assert(lock.user == user_address, 'Lock user mismatch');
    assert(lock.token_id == token_id, 'Lock token_id mismatch');
    assert(lock.amount == amount_to_lock, 'Lock amount mismatch');

    // Check that the user's balance is decreased
    let user_balance = project.balance_of(user_address, token_id);
    assert(user_balance == 0, 'User balance mismatch');

    // Check that the locker contract's balance increased
    let locker_balance = project.balance_of(locker_address, token_id);
    assert(locker_balance == amount_to_lock, 'Locker balance mismatch');

    stop_cheat_caller_address(locker_address);
}

#[test]
#[should_panic(expected: 'Not enough carbon credits')]
fn test_locker__lock_credits_insufficient_balance() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let (project_address, locker_address, _, minter_address, _) = deploy_all();

    // Grant necessary roles
    let project = IProjectDispatcher { contract_address: project_address };

    start_cheat_caller_address(project_address, owner_address);
    project.grant_minter_role(minter_address);
    project.grant_offsetter_role(locker_address);
    stop_cheat_caller_address(project_address);

    // Mint tokens to the user
    let vintages = IVintageDispatcher { contract_address: project_address };
    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint = initial_total_supply / 10; // 10% of the total supply

    buy_utils(owner_address, user_address, minter_address, cc_to_mint);
    let token_id: u256 = 1;
    let balance = project.balance_of(user_address, token_id);

    // Set the vintage status to "Audited"
    start_cheat_caller_address(project_address, owner_address);
    vintages.update_vintage_status(token_id, CarbonVintageType::Audited.into());
    stop_cheat_caller_address(project_address);

    // Approve the locker contract to transfer the tokens
    start_cheat_caller_address(project_address, user_address);
    project.set_approval_for_all(locker_address, true);
    stop_cheat_caller_address(project_address);

    // Now, call lock_credits
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };

    start_cheat_caller_address(locker_address, user_address);
    start_cheat_caller_address(project_address, user_address);

    let amount_to_lock = balance;
    let lock_duration: u64 = 1000; // Some duration
    locker.lock_credits(token_id, amount_to_lock + 1, lock_duration);
}

#[test]
#[should_panic(expected: 'Vintage status is not audited')]
fn test_locker__lock_credits_vintage_not_audited() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let (project_address, locker_address, _, minter_address, _) = deploy_all();

    // Grant necessary roles
    let project = IProjectDispatcher { contract_address: project_address };

    start_cheat_caller_address(project_address, owner_address);
    project.grant_minter_role(minter_address);
    project.grant_offsetter_role(locker_address);
    stop_cheat_caller_address(project_address);

    // Mint tokens to the user
    let vintages = IVintageDispatcher { contract_address: project_address };
    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint = initial_total_supply / 10; // 10% of the total supply

    buy_utils(owner_address, user_address, minter_address, cc_to_mint);
    let token_id: u256 = 1;
    let balance = project.balance_of(user_address, token_id);

    // Approve the locker contract to transfer the tokens
    start_cheat_caller_address(project_address, user_address);
    project.set_approval_for_all(locker_address, true);
    stop_cheat_caller_address(project_address);

    // Now, call lock_credits
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };

    start_cheat_caller_address(locker_address, user_address);
    start_cheat_caller_address(project_address, user_address);

    let amount_to_lock = balance;
    let lock_duration: u64 = 1000; // Some duration
    locker.lock_credits(token_id, amount_to_lock, lock_duration);
}

#[test]
fn test_locker__is_lock_expired() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let (project_address, locker_address, _, minter_address, _) = deploy_all();

    // Grant necessary roles
    let project = IProjectDispatcher { contract_address: project_address };

    start_cheat_caller_address(project_address, owner_address);
    project.grant_minter_role(minter_address);
    project.grant_offsetter_role(locker_address);
    stop_cheat_caller_address(project_address);

    // Mint tokens to the user
    let vintages = IVintageDispatcher { contract_address: project_address };
    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint = initial_total_supply / 10; // 10% of the total supply

    buy_utils(owner_address, user_address, minter_address, cc_to_mint);
    let token_id: u256 = 1;
    let balance = project.balance_of(user_address, token_id);

    // Set the vintage status to "Audited"
    start_cheat_caller_address(project_address, owner_address);
    vintages.update_vintage_status(token_id, CarbonVintageType::Audited.into());
    stop_cheat_caller_address(project_address);

    // Approve the locker contract to transfer the tokens
    start_cheat_caller_address(project_address, user_address);
    project.set_approval_for_all(locker_address, true);
    stop_cheat_caller_address(project_address);

    // Now, call lock_credits
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };

    start_cheat_caller_address(locker_address, user_address);
    start_cheat_caller_address(project_address, user_address);

    let amount_to_lock = balance;
    let lock_duration: u64 = 1000; // Some duration
    let current_timestamp: u64 = get_block_timestamp();
    locker.lock_credits(token_id, amount_to_lock, lock_duration);

    // Check is_lock_expired before time passes
    let lock_id: u256 = 0;
    let is_expired = locker.is_lock_expired(lock_id);
    assert(!is_expired, 'Lock should not be expired yet');

    // Simulate time passing
    let end_time: u64 = (current_timestamp + lock_duration).into();
    start_cheat_block_timestamp_global(end_time);

    // Check is_lock_expired after time passes
    let is_expired_after = locker.is_lock_expired(lock_id);
    assert(is_expired_after, 'Lock should be expired now');

    stop_cheat_caller_address(locker_address);
}

#[test]
fn test_locker__is_lock_offsettable() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let (project_address, locker_address, _, minter_address, _) = deploy_all();

    // Grant necessary roles
    let project = IProjectDispatcher { contract_address: project_address };

    start_cheat_caller_address(project_address, owner_address);
    project.grant_minter_role(minter_address);
    project.grant_offsetter_role(locker_address);
    stop_cheat_caller_address(project_address);

    // Mint tokens to the user
    let vintages = IVintageDispatcher { contract_address: project_address };
    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint = initial_total_supply / 10; // 10% of the total supply

    buy_utils(owner_address, user_address, minter_address, cc_to_mint);
    let token_id: u256 = 1;
    let balance = project.balance_of(user_address, token_id);

    // Set the vintage status to "Audited"
    start_cheat_caller_address(project_address, owner_address);
    vintages.update_vintage_status(token_id, CarbonVintageType::Audited.into());
    stop_cheat_caller_address(project_address);

    // Approve the locker contract to transfer the tokens
    start_cheat_caller_address(project_address, user_address);
    project.set_approval_for_all(locker_address, true);
    stop_cheat_caller_address(project_address);

    // Now, call lock_credits
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };

    start_cheat_caller_address(locker_address, user_address);
    start_cheat_caller_address(project_address, user_address);

    let amount_to_lock = balance;
    let lock_duration: u64 = 1000; // Some duration
    let current_timestamp: u64 = get_block_timestamp();
    locker.lock_credits(token_id, amount_to_lock, lock_duration);

    // Check is_lock_offsettable before time passes
    let lock_id: u256 = 0;
    let is_expired = locker.is_lock_expired(lock_id);
    assert(!is_expired, 'Lock should not be expired yet');

    // Simulate time passing
    let end_time: u64 = (current_timestamp + lock_duration).into();
    start_cheat_block_timestamp_global(end_time);

    // Check is_lock_offsettable after time passes and not offsetted
    let is_expired_after = locker.is_lock_expired(lock_id);
    assert(is_expired_after, 'Lock should be expired now');

    stop_cheat_caller_address(locker_address);
}

#[test]
fn test_locker__offset_credits() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let (project_address, locker_address, _, minter_address, _) = deploy_all();

    // Grant necessary roles
    let project = IProjectDispatcher { contract_address: project_address };

    start_cheat_caller_address(project_address, owner_address);
    project.grant_minter_role(minter_address);
    project.grant_offsetter_role(locker_address);
    stop_cheat_caller_address(project_address);

    // Mint tokens to the user
    let vintages = IVintageDispatcher { contract_address: project_address };
    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint = initial_total_supply / 10; // 10% of the total supply

    buy_utils(owner_address, user_address, minter_address, cc_to_mint);
    let token_id: u256 = 1;
    let balance = project.balance_of(user_address, token_id);

    // Set the vintage status to "Audited"
    start_cheat_caller_address(project_address, owner_address);
    vintages.update_vintage_status(token_id, CarbonVintageType::Audited.into());
    stop_cheat_caller_address(project_address);

    // Approve the locker contract to transfer the tokens
    start_cheat_caller_address(project_address, user_address);
    project.set_approval_for_all(locker_address, true);
    stop_cheat_caller_address(project_address);

    // Now, call lock_credits
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };

    start_cheat_caller_address(locker_address, user_address);
    start_cheat_caller_address(project_address, user_address);

    let amount_to_lock = balance;
    let lock_duration: u64 = 1000; // Some duration
    let current_timestamp: u64 = get_block_timestamp();
    locker.lock_credits(token_id, amount_to_lock, lock_duration);

    // Check that the lock is created
    let lock_id: u256 = 0;
    let lock = locker.get_lock(lock_id);
    assert(lock.id == lock_id, 'Lock ID mismatch');
    assert(lock.user == user_address, 'Lock user mismatch');
    assert(lock.token_id == token_id, 'Lock token_id mismatch');
    assert(lock.amount == amount_to_lock, 'Lock amount mismatch');
    stop_cheat_caller_address(locker_address);

    // Simulate time passing
    let end_time: u64 = (current_timestamp + lock_duration).into();
    start_cheat_block_timestamp_global(end_time);

    // Check is_lock_offsettable after time passes and not offsetted
    let is_expired_after = locker.is_lock_expired(lock_id);
    assert(is_expired_after, 'Lock should be expired now');

    stop_cheat_caller_address(locker_address);

    start_cheat_caller_address(locker_address, user_address);
    start_cheat_caller_address(project_address, locker_address);

    locker.offset_credits(lock_id);

    // Check that the lock is marked as offsetted
    let lock = locker.get_lock(lock_id);
    assert(lock.is_offsetted, 'Lock not marked offsetted');

    // Check that the locker balance is reduced
    let locker_balance = project.balance_of(locker_address, token_id);
    assert(locker_balance == 0, 'Locker balance mismatch');

    stop_cheat_caller_address(locker_address);
}

#[test]
fn test_locker__get_user_locks() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let user_address: ContractAddress = contract_address_const::<'USER'>();
    let (project_address, locker_address, _, minter_address, _) = deploy_all();

    // Grant necessary roles
    let project = IProjectDispatcher { contract_address: project_address };

    start_cheat_caller_address(project_address, owner_address);
    project.grant_minter_role(minter_address);
    project.grant_offsetter_role(locker_address);
    stop_cheat_caller_address(project_address);

    // Mint tokens to the user
    let vintages = IVintageDispatcher { contract_address: project_address };
    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint = initial_total_supply / 10; // 10% of the total supply

    buy_utils(owner_address, user_address, minter_address, cc_to_mint);
    let token_id: u256 = 1;
    let balance = project.balance_of(user_address, token_id);

    // Set the vintage status to "Audited"
    start_cheat_caller_address(project_address, owner_address);
    vintages.update_vintage_status(token_id, CarbonVintageType::Audited.into());
    stop_cheat_caller_address(project_address);

    // Approve the locker contract to transfer the tokens
    start_cheat_caller_address(project_address, user_address);
    project.set_approval_for_all(locker_address, true);
    stop_cheat_caller_address(project_address);

    start_cheat_caller_address(locker_address, user_address);
    start_cheat_caller_address(project_address, user_address);

    // Now, call lock_credits multiple times
    let locker = ILockerHandlerDispatcher { contract_address: locker_address };

    start_cheat_caller_address(locker_address, user_address);

    let amount_to_lock = balance / 4;
    let lock_duration: u64 = 1000; // Some duration

    locker.lock_credits(token_id, amount_to_lock, lock_duration);
    locker.lock_credits(token_id, amount_to_lock, lock_duration);

    // Retrieve user's locks
    let user_locks = locker.get_user_locks(user_address);

    // Check that there are two locks
    assert(user_locks.len() == 2, 'User should have two locks');

    // Check that the locks belong to the user
    let lock1 = user_locks.get(0).unwrap();
    let lock2 = user_locks.get(1).unwrap();

    assert(lock1.user == user_address, 'Lock1 user mismatch');
    assert(lock2.user == user_address, 'Lock2 user mismatch');

    stop_cheat_caller_address(locker_address);
}

