// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentPaymentAutomation {
    address public landlord;

    struct Tenant {
        address tenantAddress;
        uint256 monthlyRent;
        uint256 nextDueDate;
        bool isActive;
    }

    mapping(address => Tenant) public tenants;

    event TenantRegistered(address tenant, uint256 monthlyRent);
    event RentPaid(address tenant, uint256 amount, uint256 paidAt);
    event TenantRemoved(address tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord can perform this action");
        _;
    }

    modifier onlyTenant() {
        require(tenants[msg.sender].isActive, "Only active tenants can perform this action");
        _;
    }

    constructor() {
        landlord = msg.sender;
    }

    // Landlord registers a tenant
    function registerTenant(address _tenant, uint256 _monthlyRent) public onlyLandlord {
        require(!tenants[_tenant].isActive, "Tenant already registered");
        tenants[_tenant] = Tenant({
            tenantAddress: _tenant,
            monthlyRent: _monthlyRent,
            nextDueDate: block.timestamp + 30 days,
            isActive: true
        });

        emit TenantRegistered(_tenant, _monthlyRent);
    }

    // Tenant pays rent
    function payRent() public payable onlyTenant {
        Tenant storage t = tenants[msg.sender];
        require(msg.value == t.monthlyRent, "Incorrect rent amount");
        require(block.timestamp >= t.nextDueDate, "Rent not due yet");

        payable(landlord).transfer(msg.value);
        t.nextDueDate += 30 days;

        emit RentPaid(msg.sender, msg.value, block.timestamp);
    }

    // Landlord can remove a tenant
    function removeTenant(address _tenant) public onlyLandlord {
        require(tenants[_tenant].isActive, "Tenant not active");
        tenants[_tenant].isActive = false;
        emit TenantRemoved(_tenant);
    }

    // Get next due date for a tenant
    function getNextDueDate(address _tenant) public view returns (uint256) {
        return tenants[_tenant].nextDueDate;
    }

    // Fallback function to prevent accidental ether transfers
    receive() external payable {
        revert("Direct payments not allowed");
    }
}

