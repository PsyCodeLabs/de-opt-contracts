// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OptionInterface {

    /* ============ Events ============ */

    event buyEvent(address indexed buyer, uint256 indexed premiumPaid);
    event executeEvent(address indexed buyer, uint256 indexed quantity, uint256 amountPaid);
    event cancelEvent(address indexed writer, uint256 indexed quantity);
    event withdrawEvent(address indexed writer, uint256 indexed quantity);
    event adjustPremiumEvent(uint256 indexed oldPremium, uint256 indexed newPremium);
    event transferBuyerRoleEvent(address indexed oldBuyer, address indexed newBuyer);

    /* ============ Functions ============ */

    function init() external;

    function buy() external;

    function transfer(address buyer) external;

    function execute() external;

    function cancel() external;

    function withdraw() external;

    function adjustPremium(uint256 premium) external;

    function buyer() external returns (address);
    
}