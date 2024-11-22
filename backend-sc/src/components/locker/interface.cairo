use starknet::ContractAddress;

#[starknet::interface]
trait ILockerHandler<TContractState> {
    /// Locks a specified amount of carbon credits for a given period.
    fn lock_credits(ref self: TContractState, token_id: u256, amount: u256, lock_duration: u256);

    /// Checks if the lock period has expired for a user's locked credits.
    fn is_lock_expired(self: @TContractState, user: ContractAddress, token_id: u256) -> bool;

    /// Initiates the offsetting of locked credits after the lock period.
    fn offset_credits(ref self: TContractState, token_id: u256);

    /// Retrieves the details of locked credits for a user.
    fn get_locked_credits(
        self: @TContractState, user: ContractAddress, token_id: u256
    ) -> u256;

    /// Allows the user to withdraw credits before the lock period ends with a penalty.
    fn early_withdraw(ref self: TContractState, token_id: u256);

    /// Retrieves the contract address of offsetter
    fn get_offsetter_address(self: @TContractState) -> ContractAddress;

    /// Sets the contract address of offsetter
    fn set_offsetter_address(ref self: TContractState, address: ContractAddress);

    /// Retrieves the contract address of the NFT component
    fn get_nft_component_address(self: @TContractState) -> ContractAddress;

    /// Sets the contract address of the NFT component
    fn set_nft_component_address(ref self: TContractState, address: ContractAddress);
}
