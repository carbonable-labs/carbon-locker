use starknet::ContractAddress;

#[starknet::interface]
trait INFTComponent<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);
}
