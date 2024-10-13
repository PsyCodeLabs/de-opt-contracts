// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/primary/Call.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/primary/interfaces/AggregatorV3Interface.sol";
import "../src/secondary/Offer.sol";
import "../src/secondary/OfferFactory.sol";

contract OfferTest is Test {
    address usdtToken = 0x19Ed533D9f274DC0d1b59FB9C0d5D1C27cba8bb1; // 18 decimals
    address ethToken = 0xc302BD52985e75C1f563a47f2b5dfC4e2b5C6C7E; // 18 decimals
    address priceOracle = 0x59F1ec1f10bD7eD9B938431086bC1D9e233ECf41; // 8 decimals
    CallOption callOption;
    Offer offer;
    OfferFactory public offerFactory;

    ERC20 ethERC20 = ERC20(ethToken);
    ERC20 usdtERC20 = ERC20(usdtToken);


    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");
    address newBuyer = makeAddr("newBuyer");
    uint256 ask = 15e18;

    
    function setUp() public {

        offerFactory = new OfferFactory(usdtToken);

        uint256 premium = 10e18;
        uint256 strikePrice = 1500e8;
        uint256 quantity = 1e16;
        uint256 expiration = block.timestamp + 1 weeks;

        vm.prank(seller);
        callOption = new CallOption(ethToken, seller, premium, strikePrice, quantity, expiration, usdtToken, priceOracle);
    }


    function testBuyAndAccept() public {
        assertEq(callOption.executed(), false);

        deal(ethToken, seller, 10e16);

        // initialise callOption contract
        vm.startPrank(seller);
        ethERC20.approve(address(callOption), 10e16);
        callOption.init();
        vm.stopPrank();

        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);

        deal(usdtToken, buyer, 100e18);

        // call buy from callOption contract, by doing this you set the buyer for the Option
        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 15e18);

        // create offer for callOption
        offerFactory.createOffer(address(callOption), ask);
        uint256 lastOffer = offerFactory.getOffersCount() - 1;
        offer = Offer(offerFactory.offers(lastOffer));

        // transfer the buyer right to the offer contract
        callOption.transfer(address(offer));

        assertEq(callOption.buyer(), address(offer));
        vm.stopPrank();
        assertEq(offer.executed(), false);

        deal(usdtToken, newBuyer, offer.ask());

        vm.startPrank(newBuyer);
        usdtERC20.approve(address(offer), offer.ask());
        offer.accept();
        assertEq(callOption.buyer(), newBuyer);
    }

    function testCancel() public {
        assertEq(callOption.executed(), false);

        deal(ethToken, seller, 10e16);

        // initialise callOption contract
        vm.startPrank(seller);
        ethERC20.approve(address(callOption), 10e16);
        callOption.init();
        vm.stopPrank();

        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);

        deal(usdtToken, buyer, 100e18);

        // call buy from callOption contract, by doing this you set the buyer for the Option
        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 15e18);

        // create offer for callOption
        offerFactory.createOffer(address(callOption), ask);
        uint256 lastOffer = offerFactory.getOffersCount() - 1;
        offer = Offer(offerFactory.offers(lastOffer));

        // transfer the buyer right to the offer contract
        callOption.transfer(address(offer));

        assertEq(callOption.buyer(), address(offer));
        assertEq(offer.executed(), false);

        offer.cancel();
        assertEq(callOption.buyer(), buyer);
        vm.stopPrank();
    }

    function testCancelFails() public {
        assertEq(callOption.executed(), false);

        deal(ethToken, seller, 10e16);

        // initialise callOption contract
        vm.startPrank(seller);
        ethERC20.approve(address(callOption), 10e16);
        callOption.init();
        vm.stopPrank();

        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);

        deal(usdtToken, buyer, 100e18);

        // call buy from callOption contract, by doing this you set the buyer for the Option
        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 15e18);

        // create offer for callOption
        offerFactory.createOffer(address(callOption), ask);
        uint256 lastOffer = offerFactory.getOffersCount() - 1;
        offer = Offer(offerFactory.offers(lastOffer));

        // transfer the buyer right to the offer contract
        callOption.transfer(address(offer));
        vm.stopPrank();

        assertEq(callOption.buyer(), address(offer));
        assertEq(offer.executed(), false);

        deal(usdtToken, newBuyer, offer.ask());

        // The seller accept the offer and tranfer the Option to the new buyer
        vm.startPrank(newBuyer);
        usdtERC20.approve(address(offer), offer.ask());
        offer.accept();
        vm.stopPrank();
        
        assertEq(callOption.buyer(), newBuyer);
        assertEq(offer.executed(), true);

        vm.startPrank(buyer);
        vm.expectRevert();
        offer.cancel();
        vm.stopPrank();

        assertEq(callOption.buyer(), newBuyer);
    }

}