// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/primary/Factory.sol";
import "../src/primary/Call.sol";
import "../src/primary/Put.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/primary/interfaces/AggregatorV3Interface.sol";

contract CallOptionTest is Test {
    address usdtToken = 0x19Ed533D9f274DC0d1b59FB9C0d5D1C27cba8bb1; // 18 decimals
    address ethToken = 0xc302BD52985e75C1f563a47f2b5dfC4e2b5C6C7E; // 18 decimals
    address priceOracle = 0x59F1ec1f10bD7eD9B938431086bC1D9e233ECf41; // 8 decimals
    CallOption callOption;

    address creator = makeAddr("creator");
    address buyer = makeAddr("buyer");

    function setUp() public {
        uint256 premium = 10e18;
        uint256 strikePrice = 2000e8;
        uint256 quantity = 1e16;
        uint256 expiration = block.timestamp + 1 weeks;

        vm.prank(creator);
        callOption = new CallOption(ethToken, creator, premium, strikePrice, quantity, expiration, usdtToken, priceOracle);
    }

    function testBuyAndExecute() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();
        vm.stopPrank();

        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);

        deal(usdtToken, buyer, 100e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 20e18);

        usdtERC20.approve(address(callOption), callOption.strikeValue());
        callOption.execute();
        vm.stopPrank();

        assertEq(ethERC20.balanceOf(buyer), callOption.quantity());
        assertEq(usdtERC20.balanceOf(buyer), 70e18);
        assertEq(usdtERC20.balanceOf(creator), 30e18);
        assertEq(callOption.executed(), true);
    }

    function testExecuteLateFails() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();
        vm.stopPrank();

        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);

        deal(usdtToken, buyer, 100e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 20e18);

        usdtERC20.approve(address(callOption), callOption.strikeValue());
        vm.warp(block.timestamp + 10 days);
        vm.expectRevert();
        callOption.execute();
        vm.stopPrank();

        assertEq(ethERC20.balanceOf(buyer), 0);
        assertEq(usdtERC20.balanceOf(buyer), 90e18);
        assertEq(usdtERC20.balanceOf(creator), 10e18);
        assertEq(callOption.executed(), false);
    }

    function testAdjustPremium() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();

        assertEq(callOption.premium(), 10e18);

        callOption.adjustPremium(20e18);
        vm.stopPrank();

        assertEq(callOption.premium(), 20e18);
    }

    function testAdjustPremiumFails() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();
        vm.stopPrank();

        deal(usdtToken, buyer, 100e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 20e18);
        vm.stopPrank();

        assertEq(callOption.premium(), 10e18);

        vm.prank(creator);
        vm.expectRevert();
        callOption.adjustPremium(20e18);
        
        assertEq(callOption.premium(), 10e18);
    }

    function testTransferBuyer() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();
        vm.stopPrank();

        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);

        deal(usdtToken, buyer, 100e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 20e18);

        address buyer2 = makeAddr("buyer2");

        callOption.transfer(buyer2);

        vm.stopPrank();

        assertEq(callOption.buyer(), buyer2);
    }

    function testTransferBuyerFails() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();
        vm.stopPrank();

        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);

        deal(usdtToken, buyer, 100e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 20e18);

        vm.stopPrank();

        address buyer2 = makeAddr("buyer2");

        vm.prank(buyer2);
        vm.expectRevert();
        callOption.transfer(buyer2);

        assertEq(callOption.buyer(), buyer);
    }

    function testCancel() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();

        assertEq(callOption.inited(), true);
        assertEq(callOption.executed(), false);
        assertEq(ethERC20.balanceOf(address(callOption)), 1e16);

        skip(5 days);
        callOption.cancel();
        vm.stopPrank();

        assertEq(callOption.executed(), true);
        assertEq(ethERC20.balanceOf(address(callOption)), 0);
        assertEq(ethERC20.balanceOf(creator), 1e16);
    }

    function testCancelFails() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();

        assertEq(callOption.inited(), true);
        assertEq(callOption.executed(), false);
        assertEq(ethERC20.balanceOf(address(callOption)), 1e16);


        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);
        vm.stopPrank();

        deal(usdtToken, buyer, 100e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 20e18);

        vm.stopPrank();

        vm.prank(creator);
        vm.expectRevert();
        callOption.cancel();

        assertEq(callOption.executed(), false);
        assertEq(ethERC20.balanceOf(address(callOption)), 1e16);
        assertEq(ethERC20.balanceOf(creator), 0);
        assertEq(usdtERC20.balanceOf(buyer), 90e18);
        assertEq(usdtERC20.balanceOf(creator), 10e18);
    }

    function testWithdraw() public {
        assertEq(callOption.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption), 1e16);
        callOption.init();
        vm.stopPrank();

        assertEq(callOption.inited(), true);
        assertEq(callOption.buyer() != address(0), false);

        deal(usdtToken, buyer, 100e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption), 10e18);
        callOption.buy();
        vm.stopPrank();

        assertEq(callOption.buyer() != address(0), true);
        assertEq(callOption.executed(), false);
        assertEq(callOption.buyer(), buyer);
        assertEq(callOption.strikeValue(), 20e18);

        vm.warp(block.timestamp + 8 days);
        vm.prank(creator);
        callOption.withdraw();

        assertEq(ethERC20.balanceOf(creator), 1e16);
        assertEq(usdtERC20.balanceOf(buyer), 90e18);
        assertEq(usdtERC20.balanceOf(creator), 10e18);
        assertEq(callOption.executed(), true);
    }

    function testExecuteFails() public {
        uint256 _premium = 10e18;
        uint256 _strikePrice = 3800e8;
        uint256 _quantity = 1e16;
        uint256 _expiration = block.timestamp + 1 weeks;

        vm.prank(creator);
        CallOption callOption2 = new CallOption(ethToken, creator, _premium, _strikePrice, _quantity, _expiration, usdtToken, priceOracle);

        assertEq(callOption2.inited(), false);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(ethToken, creator, 1e16);

        vm.startPrank(creator);
        ethERC20.approve(address(callOption2), 1e16);
        callOption2.init();
        vm.stopPrank();

        assertEq(callOption2.inited(), true);
        assertEq(callOption2.buyer() == address(0), true);

        deal(usdtToken, buyer, 100e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(callOption2), 10e18);
        callOption2.buy();

        assertEq(callOption2.buyer() == address(0), false);
        assertEq(callOption2.executed(), false);
        assertEq(callOption2.buyer(), buyer);
        assertEq(callOption2.strikeValue(), 38e18);

        usdtERC20.approve(address(callOption2), callOption2.strikeValue());
        vm.expectRevert();
        callOption2.execute();
        vm.stopPrank();

        assertEq(ethERC20.balanceOf(buyer), 0);
        assertEq(usdtERC20.balanceOf(buyer), 90e18);
        assertEq(usdtERC20.balanceOf(creator), 10e18);
        assertEq(callOption2.executed(), false);
    }
}
