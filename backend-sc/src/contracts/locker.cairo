use starknet::ContractAddress;

#[starknet::contract]
mod Locker {
    use starknet::ContractAddress;

    // Constants
    const OWNER_ROLE: felt252 = selector!("Owner");
    const LOCKER_ROLE: felt252 = selector!("Locker");

    // Ownable
    use openzeppelin::access::ownable::OwnableComponent;
    // Upgradable
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    //SRC5
    use openzeppelin::introspection::src5::SRC5Component;
    // Access Control - RBAC
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    // Locker
    use carbon_locker::components::locker::locker_handler::LockerComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: LockerComponent, storage: locker_handler, event: LockerEvent);


    // ABI
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        OwnableComponent::OwnableCamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl LockerImpl = LockerComponent::LockerHandlerImpl<ContractState>;
    // Access Control
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl LockerInternalImpl = LockerComponent::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        locker_handler: LockerComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        LockerEvent: LockerComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        carbonable_project_address: ContractAddress,
        offsetter_address: ContractAddress,
        owner: ContractAddress,
        penalty_recipient: ContractAddress,
    ) {
        self.ownable.initializer(owner);
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(OWNER_ROLE, owner);
        self.locker_handler.initializer(carbonable_project_address, offsetter_address);
        self.accesscontrol.set_role_admin(OWNER_ROLE, OWNER_ROLE);
        self.accesscontrol.set_role_admin(LOCKER_ROLE, OWNER_ROLE);
        self.locker_handler.set_penalty_config(5, penalty_recipient); // 5% penalty by default
    }
}