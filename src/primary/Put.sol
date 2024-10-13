// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {OptionInterface} from "./interfaces/OptionInterface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title PutOption
 * @author PsyCode Labs
 *
 * Contract that handles the logic and implementation of put options, this contract represents
 * a single put option
 */
contract PutOption is OptionInterface {
    
    /* ============ State Variables ============ */

    // address of the token on which option is being created, eg. ETH
    address public asset;
    // address of the creator/writer of the contract
    address public creator;
    // address of the current buyer who holds the right to execute the option
    address public buyer;

    // cost of buying the option (in USDT)
    uint256 public premium;
    // price below which the option is executable
    uint256 public strikePrice;
    // amount of asset token
    uint256 public quantity;
    // timestamp after which the option expires
    uint256 public expiration;
    // price at which the option was executed, if executed
    uint256 public executedPrice;

    // boolean to check whether the creator/writer has transferred required assets
    bool public inited;
    // boolean to check whether the option has been executed or not
    bool public executed;

    // quote token (USDT)
    ERC20 public premiumToken;

    // oracle to call for asset/USDT price feed
    AggregatorV3Interface public priceOracle;

    /* ============ Constructor ============ */

    constructor(
        address _asset,
        address _creator,
        uint256 _premium,
        uint256 _strikePrice,
        uint256 _quantity,
        uint256 _expiration,
        address _premiumToken,
        address _priceOracle
    ) {
        asset = _asset;
        creator = _creator;
        premium = _premium;
        strikePrice = _strikePrice;
        quantity = _quantity;
        expiration = _expiration;
        buyer = address(0);
        executed = false;
        inited = false;
        premiumToken = ERC20(_premiumToken);
        priceOracle = AggregatorV3Interface(_priceOracle);
    }

    /* ============ Modifiers ============ */

    /**
     * Throws if option has not been initialized
     */
    modifier isInited() {
        checkInit();
        _;
    }

    /**
     * Throws if option has already been bought
     */
    modifier notBought() {
        checkBought();
        _;
    }

    /**
     * Throws if option has already been executed
     */
    modifier notExecuted() {
        checkExecuted();
        _;
    }

    /**
     * Throws if function is called by any address other than buyer
     */
    modifier onlyBuyer() {
        checkBuyer(msg.sender);
        _;
    }

    /**
     * Throws if function is called by any address other than creator
     */
    modifier onlyCreator() {
        checkCreator(msg.sender);
        _;
    }

    /**
     * Throws if the current block timestamp is greater than expiration timestamp of the option
     */
    modifier notExpired() {
        checkExpiration(block.timestamp);
        _;
    }

    /* ============ Functions ============ */

    /**
     * Initializes Option - the creator locks in required amount of USDT tokens
     */
    function init() external onlyCreator {
        require(inited == false, "Option contract has already been initialized");
        inited = true;
        require(premiumToken.transferFrom(msg.sender, address(this), strikeValue()), "Transfer failed");
    }

    /**
     * Buying Option - this function is called by a buyer who is interested, this function can be
     *     only called once, after that the role of buyer can only be transferred using 'transfer'
     */
    function buy() external notBought isInited notExpired {
        require(msg.sender != creator, "Creator cannot buy their own option");
        buyer = msg.sender;
        require(premiumToken.transferFrom(msg.sender, creator, premium), "Premium transfer failed");
        emit buyEvent(msg.sender, premium);
    }

    /**
     * Transferring Buyer Role
     *
     * @param newBuyer - address of the new buyer
     */
    function transfer(address newBuyer) external onlyBuyer isInited notExpired {
        emit transferBuyerRoleEvent(buyer, newBuyer);
        buyer = newBuyer;
    }

    /**
     * Executing Option - this function can be only called when the price of the asset is equal to or
     *     lower than the strike price, upon doing so, the contract will transfer locked-in USDT
     *     tokens to the buyer and in return buyer will pay asset tokens to the creator
     */
    function execute() external onlyBuyer notExecuted isInited notExpired {
        require(_checkPosition(), "Option is out of the money");
        executed = true;
        uint256 amountToTransfer = strikeValue();
        require(premiumToken.transfer(buyer, amountToTransfer), "Asset transfer failed");
        require(ERC20(asset).transferFrom(buyer, creator, quantity), "Payment failed");
        emit executeEvent(buyer, quantity, amountToTransfer);
    }

    /**
     * Oracle Call - this is a helper function which calls the oracle contract to get the latest price
     *     data and returns a bool indicating whether the current asset price is equal or lower than
     *     the strike price, it also sets the value of executedPrice to the latest price
     */
    function _checkPosition() internal returns (bool) {
        (, int256 price,,,) = priceOracle.latestRoundData();
        executedPrice = uint256(price);
        return uint256(price) <= strikePrice;
    }

    /**
     * Cancelling Option - this function can be called only by the creator if the option has been
     *     initialized and there has been no buyer, which means the creator still can withdraw
     *     his USDT tokens and cancel this contract
     */
    function cancel() external onlyCreator notBought isInited notExpired notExecuted {
        executed = true;
        require(premiumToken.transfer(creator, strikeValue()), "Asset transfer failed");
        emit cancelEvent(creator, strikeValue());
    }

    /**
     * Withdraw Assets - this function can be called only by the creator after the option has expired
     *     and if it was not executed by the buyer, this results in the creator receiving back his
     *     locked-in USDT tokens
     */
    function withdraw() external onlyCreator isInited notExecuted {
        require(block.timestamp > expiration, "Option not expired yet");
        executed = true;
        require(premiumToken.transfer(creator, strikeValue()), "Asset transfer failed");
        emit withdrawEvent(creator, strikeValue());
    }

    /**
     * Adjusting Premium - this function can be called only by the creator if the option has been
     *     initialized and there has been no buyer, this results in adjusting the price/premium for
     *     the option, a creator might want to make use of this function if there has been a sudden
     *     change in the market dynamics and re-evaluate his/her position
     *
     * @param newPremium - new amount in USDT
     */
    function adjustPremium(uint256 newPremium) external onlyCreator notBought notExpired {
        emit adjustPremiumEvent(premium, newPremium);
        premium = newPremium;
    }

    /**
     * Strike Value - this is a helper function which returns amount in USDT that is to be paid by
     *     the buyer if he/she executes the option
     */
    function strikeValue() public view returns (uint256) {
        uint256 intermediateValue = Math.mulDiv(strikePrice, quantity, 10**priceOracle.decimals());
        return Math.mulDiv(intermediateValue, 10**premiumToken.decimals(), 10**ERC20(asset).decimals());
    }

    /**
     * Option Data - this a view function which is used to return the whole state/data of the option
     *     in a single request
     */
    function optionData() public view returns (address, uint256, uint256, uint256, uint256, bool, bool) {
        return (asset, strikePrice, expiration, premium, quantity, inited, executed);
    }

    /* ============ Internal Modifier Functions ============ */

    function checkInit() internal view {
        require(inited, "Contract has not been inited by the creator!");
    }

    function checkBought() internal view {
        require(buyer == address(0), "Contract has been bought!");
    }

    function checkExecuted() internal view {
        require(!executed, "Contract has been executed!");
    }

    function checkBuyer(address caller) internal view {
        require(caller == buyer, "Only the buyer can call this function!");
    }

    function checkCreator(address caller) internal view {
        require(caller == creator, "Only the creator can call this function!");
    }

    function checkExpiration(uint256 timestamp) internal view {
        require(timestamp <= expiration, "Option expired");
    }
}
