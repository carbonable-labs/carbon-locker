// Starknet deps

use starknet::{ContractAddress, contract_address_const};

// External deps

use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpy, spy_events, EventSpyTrait,
    EventSpyAssertionsTrait, start_cheat_caller_address, stop_cheat_caller_address
};

// Models

use carbon_v3::models::carbon_vintage::{CarbonVintage, CarbonVintageType};
use carbon_v3::models::constants::{CC_DECIMALS_MULTIPLIER, MULTIPLIER_TONS_TO_MGRAMS};

// Components

use carbon_v3::components::vintage::interface::{
    IVintage, IVintageDispatcher, IVintageDispatcherTrait
};
use carbon_v3::components::minter::interface::{IMint, IMintDispatcher, IMintDispatcherTrait};
use openzeppelin::token::erc1155::ERC1155Component;


// Contracts

use carbon_v3::contracts::project::{
    Project, IExternalDispatcher as IProjectDispatcher,
    IExternalDispatcherTrait as IProjectDispatcherTrait
};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


///
/// Mock Data
///

const DEFAULT_REMAINING_MINTABLE_CC: u256 = 82500000000000;
const STARTING_YEAR: u32 = 2024;


fn get_mock_absorptions() -> Span<u256> {
    let absorptions: Span<u256> = array![
        0,
        100000000000,
        479914660000,
        888286050000,
        1184381400000,
        3709225070000,
        6234068740000,
        8758912410000,
        11283756080000,
        13808599760000,
        20761757210000,
        27714914660000,
        34668072120000,
        41621229570000,
        48574387030000,
        55527544480000,
        62480701930000,
        69433859390000,
        76387016840000,
        80000000000000,
        82500000000000,
    ]
        .span();

    let mut yearly_absorptions: Array<u256> = array![];
    let mut index: u32 = 0;
    loop {
        if index >= absorptions.len() - 1 {
            break;
        }
        let current_abs = *absorptions.at(index + 1) - *absorptions.at(index);
        yearly_absorptions.append(current_abs);
        index += 1;
    };

    let yearly_absorptions = yearly_absorptions.span();
    yearly_absorptions
}

//
/// Tests
//

fn deploy_project() -> ContractAddress {
    let contract = snf::declare("Project").expect('Declaration failed').contract_class();
    let number_of_years: u64 = 20;
    let mut calldata: Array<felt252> = array![
        contract_address_const::<'OWNER'>().into(), STARTING_YEAR.into(), number_of_years.into()
    ];
    let (contract_address, _) = contract.deploy(@calldata).expect('Project deployment failed');

    contract_address
}

fn setup_project(contract_address: ContractAddress, yearly_absorptions: Span<u256>) {
    let vintages = IVintageDispatcher { contract_address };
    // Fake the owner to call set_vintages and set_project_carbon which can only be run by owner
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    start_cheat_caller_address(contract_address, owner_address);
    vintages.set_vintages(yearly_absorptions, STARTING_YEAR);
    stop_cheat_caller_address(contract_address);
}

fn default_setup_and_deploy() -> ContractAddress {
    let project_address = deploy_project();
    let yearly_absorptions: Span<u256> = get_mock_absorptions();
    setup_project(project_address, yearly_absorptions);
    project_address
}


fn deploy_locker(
    project_address: ContractAddress, offsetter_address: ContractAddress
) -> ContractAddress {
    let contract = snf::declare("Locker").expect('Declaration failed').contract_class();
    let mut calldata: Array<felt252> = array![
        project_address.into(), offsetter_address.into(), contract_address_const::<'OWNER'>().into(), contract_address_const::<'NGO'>().into()
    ];
    let (contract_address, _) = contract.deploy(@calldata).expect('Locker deployment failed');

    contract_address
}

/// Deploy erc20 contract.
fn deploy_erc20() -> ContractAddress {
    let contract = snf::declare("USDCarb").expect('Declaration failed').contract_class();
    let owner: ContractAddress = contract_address_const::<'OWNER'>();
    let mut calldata: Array<felt252> = array![];
    calldata.append(owner.into());
    calldata.append(owner.into());
    let (contract_address, _) = contract.deploy(@calldata).expect('Erc20 deployment failed');

    contract_address
}


/// Deploys a minter contract.
fn deploy_minter(
    project_address: ContractAddress, payment_address: ContractAddress
) -> ContractAddress {
    let contract = snf::declare("Minter").expect('Declaration failed').contract_class();
    let owner: ContractAddress = contract_address_const::<'OWNER'>();
    start_cheat_caller_address(project_address, owner);
    let public_sale: bool = true;
    let low: felt252 = DEFAULT_REMAINING_MINTABLE_CC.low.into();
    let high: felt252 = DEFAULT_REMAINING_MINTABLE_CC.high.into();
    let unit_price: felt252 = 11000000; // $11, 6 decimals like USDC
    let mut calldata: Array<felt252> = array![
        project_address.into(),
        payment_address.into(),
        public_sale.into(),
        low,
        high,
        unit_price,
        0,
        owner.into()
    ];

    let (contract_address, _) = contract.deploy(@calldata).expect('Minter deployment failed');
    contract_address
}

/// Deploys the offsetter contract.
fn deploy_offsetter(project_address: ContractAddress) -> ContractAddress {
    let contract = snf::declare("Offsetter").expect('Declaration failed').contract_class();
    let owner: ContractAddress = contract_address_const::<'OWNER'>();
    let mut calldata: Array<felt252> = array![];
    calldata.append(project_address.into());
    calldata.append(owner.into());

    let (contract_address, _) = contract.deploy(@calldata).expect('Offsetter deployment failed');

    contract_address
}

fn deploy_all() -> (
    ContractAddress, ContractAddress, ContractAddress, ContractAddress, ContractAddress
) {
    let project_address = default_setup_and_deploy();
    let offsetter_address = deploy_offsetter(project_address);
    let locker_address = deploy_locker(project_address, offsetter_address);
    let erc20_address = deploy_erc20();
    let minter_address = deploy_minter(project_address, erc20_address);
    (project_address, locker_address, erc20_address, minter_address, offsetter_address)
}

// Copied from carbon_v3
/// Utility function to buy a certain amount of carbon credits
/// That amount is minted across all vintages
/// If Bob buys 100 carbon credits, and the vintage 2024 has 10% of the total supply,
/// Bob will have 10 carbon credits in 2024
fn buy_utils(
    owner_address: ContractAddress,
    caller_address: ContractAddress,
    minter_address: ContractAddress,
    total_cc_amount: u256
) {
    // [Prank] Use caller (usually user) as caller for the Minter contract
    start_cheat_caller_address(minter_address, caller_address);
    let minter = IMintDispatcher { contract_address: minter_address };
    let erc20_address: ContractAddress = minter.get_payment_token_address();
    let erc20 = IERC20Dispatcher { contract_address: erc20_address };

    // If user wants to buy 1 carbon credit, the input should be 1*MULTIPLIER_TONS_TO_MGRAMS
    let money_to_buy = total_cc_amount * minter.get_unit_price() / MULTIPLIER_TONS_TO_MGRAMS;

    // [Prank] Use owner as caller for the ERC20 contract
    start_cheat_caller_address(erc20_address, owner_address); // Owner holds initial supply

    let success = erc20.transfer(caller_address, money_to_buy);
    assert(success, 'Transfer failed');

    // [Prank] Use caller address (usually user) as caller for the ERC20 contract
    start_cheat_caller_address(erc20_address, caller_address);
    erc20.approve(minter_address, money_to_buy);

    // [Prank] Use Minter as caller for the ERC20 contract
    start_cheat_caller_address(erc20_address, minter_address);
    // [Prank] Use caller (usually user) as caller for the Minter contract
    start_cheat_caller_address(minter_address, caller_address);
    minter.public_buy(total_cc_amount);

    stop_cheat_caller_address(minter_address);
    stop_cheat_caller_address(erc20_address);
}
