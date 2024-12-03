use starknet::ContractAddress;

#[starknet::interface]
trait INFTComponent<TContractState> {
    fn initializer(
        ref self: TContractState, name: ByteArray, symbol: ByteArray, base_uri: ByteArray
    );
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn burn(ref self: TContractState, token_id: u256);
}
