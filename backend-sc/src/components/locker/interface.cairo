use starknet::ContractAddress;

const PENALTY_SCALING_FACTOR: u256 = 10000;

#[derive(Copy, Drop, Debug, Hash, starknet::Store, Serde, PartialEq)]
struct Lock {
    id: u256, // Unique ID of the lock
    user: ContractAddress,
    token_id: u256, // token_id locked, related to vintage
    amount: u256,
    start_time: u64,
    end_time: u64,
    offsettable: bool,
    is_offsetted: bool
}

#[starknet::interface]
trait ILockerHandler<TContractState> {
    /// Locks a specified amount of carbon credits for a given period.
    fn lock_credits(ref self: TContractState, token_id: u256, amount: u256, lock_duration: u64);

    /// Checks if the lock period has expired for a user's locked credits.
    fn is_lock_expired(self: @TContractState, lock_id: u256) -> bool;

    /// Checks if the lock is offsettable.
    fn is_lock_offsettable(self: @TContractState, lock_id: u256) -> bool;

    /// Initiates the offsetting of locked credits after the lock period.
    fn offset_credits(ref self: TContractState, lock_id: u256);

    fn terminate_lock_with_penalty(ref self: TContractState, lock_id: u256, withdraw_amount: u256);

    /// Retrieves the details of a Lock.
    fn get_lock(self: @TContractState, lock_id: u256) -> Lock;

    /// Retrieves the details of locked credits for a user.
    fn get_user_locks(self: @TContractState, user: ContractAddress) -> Span<Lock>;

    /// Retrieves the contract address of offsetter
    fn get_offsetter_address(self: @TContractState) -> ContractAddress;

    /// Sets the contract address of offsetter
    fn set_offsetter_address(ref self: TContractState, address: ContractAddress);

    /// Retrieves the penalty_multiplier
    fn get_penalty_multiplier(self: @TContractState) -> u64;

    /// Retrieves the penalty_recipient
    fn get_penalty_recipient(self: @TContractState) -> ContractAddress;

    /// Retrieves the contract address of offprojectsetter
    fn get_project_address(self: @TContractState) -> ContractAddress;

    /// Sets the contract address of project
    fn set_project_address(ref self: TContractState, address: ContractAddress);

    fn set_penalty_config(
        ref self: TContractState, penalty_multiplier: u64, penalty_recipient: ContractAddress
    );

    /// Retrieves the contract address of the NFT component
    fn get_nft_component_address(self: @TContractState) -> ContractAddress;

    /// Sets the contract address of the NFT component
    fn set_nft_component_address(ref self: TContractState, address: ContractAddress);
}
