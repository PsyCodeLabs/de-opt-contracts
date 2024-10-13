// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../src/primary/Factory.sol";

contract FactoryTests is Test {
    OptionsFactory public factory;
    address usdtToken = 0x19Ed533D9f274DC0d1b59FB9C0d5D1C27cba8bb1;
    address ethToken = 0xc302BD52985e75C1f563a47f2b5dfC4e2b5C6C7E;
    address btcToken = 0x3b5dAAE6d0a1B98EF8B2E6B65206c93c8cE55841;
    address priceOracle = 0x59F1ec1f10bD7eD9B938431086bC1D9e233ECf41;
    address priceOracle2 = 0x87dce67002e66C17BC0d723Fe20D736b80CAaFda;

    address creator = makeAddr("creator");
    address owner = makeAddr("owner");

    function setUp() public {
        vm.startPrank(owner);
        factory = new OptionsFactory(usdtToken);
        factory.setPriceOracle(ethToken, priceOracle);
        factory.setPriceOracle(btcToken, priceOracle2);
        vm.stopPrank();
    }

    function testCreateCallOption() public {
        uint256 premium = 1e18;
        uint256 strikePrice = 6e8;
        uint256 quantity = 1e5;
        uint256 expiration = block.timestamp + 1 weeks;

        vm.prank(creator);
        factory.createCallOption(btcToken, premium, strikePrice, quantity, expiration);

        // assertEq(factory.callOptions.length, 1);

        CallOption callOption = CallOption(factory.callOptions(0));
        assertEq(callOption.asset(), address(btcToken));
        assertEq(callOption.premium(), premium);
        assertEq(callOption.strikePrice(), strikePrice);
        assertEq(callOption.quantity(), quantity);
        assertEq(callOption.expiration(), expiration);
        assertEq(callOption.strikeValue(), 6e5);
    }

    function testCreatePutOption() public {
        uint256 premium = 100e18;
        uint256 strikePrice = 3500e8;
        uint256 quantity = 1e18;
        uint256 expiration = block.timestamp + 1 weeks;

        vm.prank(creator);
        factory.createPutOption(ethToken, premium, strikePrice, quantity, expiration);

        // assertEq(putOptions.length, 1);

        PutOption putOption = PutOption(factory.putOptions(0));
        assertEq(putOption.asset(), ethToken);
        assertEq(putOption.premium(), premium);
        assertEq(putOption.strikePrice(), strikePrice);
        assertEq(putOption.quantity(), quantity);
        assertEq(putOption.expiration(), expiration);
    }

    function testGasSanity() public {
        deal(creator, 100e18);
        uint256 premium = 100e18;
        uint256 strikePrice = 3500e8;
        uint256 quantity = 1e18;
        uint256 expiration = block.timestamp + 1 weeks;

        vm.startPrank(creator);

        uint256 firstCreateStart = gasleft();
        factory.createCallOption(ethToken, premium, strikePrice, quantity, expiration);
        uint256 firstCreateCost = firstCreateStart - gasleft();

        uint256 firstPutStart = gasleft();
        factory.createPutOption(ethToken, premium, strikePrice, quantity, expiration);
        uint256 putCreateCost = firstPutStart - gasleft();

        console2.log("Gas Cost Call First: %s", firstCreateCost);
        console2.log("Gas Cost Put First: %s", putCreateCost);

        for (uint i = 0; i < 10; i++) {
            factory.createCallOption(ethToken, premium, strikePrice, quantity, expiration);
            factory.createPutOption(ethToken, premium, strikePrice, quantity, expiration);
        }

        uint256 lastCreateStart = gasleft();
        factory.createCallOption(ethToken, premium, strikePrice, quantity, expiration);
        uint256 lastCreateCost = lastCreateStart - gasleft();

        uint256 lastPutCreateStart = gasleft();
        factory.createPutOption(ethToken, premium, strikePrice, quantity, expiration);
        uint256 lastPutCreateCost = lastPutCreateStart - gasleft();

        console2.log("Gas Cost Call Last: %s", lastCreateCost);
        console2.log("Gas Cost Call Last: %s", lastPutCreateCost);
    
        vm.stopPrank();
    }

    function testSetPriceOracleFails() public {
        vm.startPrank(creator);
        vm.expectRevert();
        factory.setPriceOracle(ethToken, address(0));
        vm.stopPrank();
    }

    function testSetPriceOracle() public {
        vm.startPrank(owner);
        factory.setPriceOracle(ethToken, address(0));
        vm.stopPrank();   
    }
}