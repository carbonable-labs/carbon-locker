use starknet::ContractAddress;

const LOCKER_ROLE: felt252 = selector!("Locker");

use carbon_locker::components::locker::interface::Lock;

#[starknet::interface]
trait INFTComponent<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256, lock_data: Lock);
    fn burn(ref self: TContractState, token_id: u256);
}
