// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Offer} from "./Offer.sol";
import "../primary/interfaces/OptionInterface.sol";

/**
 * @title OfferFactory
 * @author PsyCode Labs
 *
 * Contract that handles the logic and implementation of a factory contract which is responsible
 * for creating new offers and keeping a list of all offers
 *
 */
contract OfferFactory {

    /* ============ State Variables ============ */

    // quote token (USDT)
    address public premiumToken;
    // array to store addresses of all deployed offers
    address[] public offers;

    /* ============ Events ============ */

    event OfferCreated(address indexed optionContract, uint256 indexed ask, address seller);

    /* ============ Constructor ============ */

    constructor(address _premiumToken) {
        premiumToken = _premiumToken;
    }

    /**
     * Offer Creation - this function creates a new offer with the provided option address and ask amount,
     *     the newly created offer is added to offers array
     * 
     * @param _optionContract - address of an option contract
     * @param _ask - amount in USDT that the seller expects to receive
     */
    function createOffer(address _optionContract, uint256 _ask) external {
        require(OptionInterface(_optionContract).buyer() == msg.sender, "The offer contract has not been authorized yet!");
        Offer newOffer = new Offer(_optionContract, msg.sender, premiumToken, _ask);
        offers.push(address(newOffer));
        emit OfferCreated(_optionContract, _ask, msg.sender);
    }

    /**
     * Offer Getter - this function returns a complete list (addresses) of offers created till date
     */
    function getOffersCount() external view returns (uint256) {
        return offers.length;
    }
    
}
