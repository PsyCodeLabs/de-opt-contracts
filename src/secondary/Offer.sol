// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../primary/interfaces/OptionInterface.sol";

/**
 * @title Offer
 * @author PsyCode Labs
 *
 * Contract that handles the logic and implementation of an Offer (reselling of an option), each Offer
 * corresponds to a single option which can be either call or put
 *
 */
contract Offer {
    
    /* ============ State Variables ============ */

    // address of the current buyer of an option who wants to resell
    address public seller;

    // amount that the seller wants in USDT
    uint256 public ask;

    // boolean to indicate whether offer has been executed or not
    bool public executed;

    // underlying option contract
    OptionInterface public optionContract;

    // quote token (USDT)
    IERC20 public premiumToken;

    /* ============ Events ============ */

    event OfferBought(address indexed optionAddress, uint256 indexed ask, address buyer, address seller);

    event OfferCancelled(address indexed optionAddress, uint256 indexed ask);

    /* ============ Constructor ============ */

    constructor(address _optionContract, address _seller, address _premiumToken, uint256 _ask) {
        optionContract = OptionInterface(_optionContract);
        executed = false;
        seller = _seller;
        ask = _ask;
        premiumToken = IERC20(_premiumToken);
    }

    /* ============ Modifiers ============ */

    /**
     * Throws if buyer of underlying option contract is not this offer contract, the seller will have
     *     to transfer the buyer role (of option) to corresponding offer contract
     */
    modifier isAuthorized() {
        require(optionContract.buyer() == address(this), "The offer contract has not been authorized yet!");
        _;
    }

    /**
     * Throws if offer is already executed
     */
    modifier isExecutable() {
        require(executed == false, "The offer contract has already been executed!");
        _;
    }

    /* ============ Functions ============ */

    /**
     * Accept Offer - this function can be called by any interested buyer who want to accept the offer
     *     and claim the buyer role of the underlying option, buyer will have to transfer asked
     *     amount of USDT
     */
    function accept() external isAuthorized isExecutable {
        require(msg.sender != seller, "The seller should call the cancel function instead");
        executed = true;
        require(premiumToken.transferFrom(msg.sender, seller, ask), "Ask transfer failed");
        optionContract.transfer(msg.sender);

        emit OfferBought(address(optionContract), ask, msg.sender, seller);
    }

    /**
     * Revert Offer - this function can only be called by the seller, this will mark offer as execute
     *     and contract will transfer the buyer role back to the seller
     */
    function cancel() external isAuthorized isExecutable {
        require(msg.sender == seller, "Only the seller can call this function!");
        executed = true;
        optionContract.transfer(seller);

        emit OfferCancelled(address(optionContract), ask);
    }
}
