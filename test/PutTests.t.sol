// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/primary/Factory.sol";
import "../src/primary/Call.sol";
import "../src/primary/Put.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/primary/interfaces/AggregatorV3Interface.sol";

contract PutOptionTest is Test {
    OptionsFactory public factory;
    address usdtToken = 0x19Ed533D9f274DC0d1b59FB9C0d5D1C27cba8bb1; // 18 decimals
    address ethToken = 0xc302BD52985e75C1f563a47f2b5dfC4e2b5C6C7E; // 18 decimals
    address priceOracle = 0x59F1ec1f10bD7eD9B938431086bC1D9e233ECf41; // 8 decimals
    PutOption putOption;

    address creator = makeAddr("creator");
    address buyer = makeAddr("buyer");

    function setUp() public {
        factory = OptionsFactory(0xA5192B03B520aF7214930936C958CF812e361CD3);
        uint256 premium = 10e18;
        uint256 strikePrice = 3800e8;
        uint256 quantity = 1e16;
        uint256 expiration = block.timestamp + 1 weeks;

        vm.prank(creator);
        putOption = new PutOption(ethToken, creator, premium, strikePrice, quantity, expiration, usdtToken, priceOracle);
    }

    function testBuyAndExecute() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();
        vm.stopPrank();

        assertEq(putOption.inited(), true);
        assertEq(putOption.buyer() == address(0), true);

        deal(usdtToken, buyer, 10e18);
        deal(ethToken, buyer, 1e16);

        vm.startPrank(buyer);
        usdtERC20.approve(address(putOption), 10e18);
        putOption.buy();

        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(putOption.buyer() == address(0), false);
        assertEq(putOption.executed(), false);
        assertEq(putOption.buyer(), buyer);

        ethERC20.approve(address(putOption), putOption.strikeValue());
        putOption.execute();
        vm.stopPrank();

        assertEq(ethERC20.balanceOf(creator), putOption.quantity());
        assertEq(usdtERC20.balanceOf(buyer), putOption.strikeValue());
        assertEq(usdtERC20.balanceOf(creator), 10e18);
        assertEq(putOption.executed(), true);
    }

    function testBuyExecuteLateFails() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();
        vm.stopPrank();

        assertEq(putOption.inited(), true);
        assertEq(putOption.buyer() == address(0), true);

        deal(usdtToken, buyer, 10e18);
        deal(ethToken, buyer, 1e16);

        vm.startPrank(buyer);
        usdtERC20.approve(address(putOption), 10e18);
        putOption.buy();

        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(putOption.buyer() == address(0), false);
        assertEq(putOption.executed(), false);
        assertEq(putOption.buyer(), buyer);

        ethERC20.approve(address(putOption), putOption.strikeValue());
        skip(10 days);
        vm.expectRevert();
        putOption.execute();
        vm.stopPrank();

        assertEq(ethERC20.balanceOf(creator), 0);
        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(usdtERC20.balanceOf(creator), 10e18);
        assertEq(putOption.executed(), false);
    }

    function testAdjustPremium() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();

        assertEq(putOption.premium(), 10e18);

        putOption.adjustPremium(20e18);
        vm.stopPrank();

        assertEq(putOption.premium(), 20e18);
    }

    function testAdjustPremiumFails() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 usdtERC20 = ERC20(usdtToken);
        
        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();
        vm.stopPrank();

        assertEq(putOption.inited(), true);
        assertEq(putOption.buyer() == address(0), true);

        deal(usdtToken, buyer, 10e18);
        deal(ethToken, buyer, 1e16);

        vm.startPrank(buyer);
        usdtERC20.approve(address(putOption), 10e18);
        putOption.buy();
        vm.stopPrank();

        assertEq(putOption.premium(), 10e18);

        vm.prank(creator);
        vm.expectRevert();
        putOption.adjustPremium(20e18);
        vm.stopPrank();

        assertEq(putOption.premium(), 10e18);
    }

    function testTransferBuyer() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();
        vm.stopPrank();

        assertEq(putOption.inited(), true);
        assertEq(putOption.buyer() == address(0), true);

        deal(usdtToken, buyer, 10e18);
        deal(ethToken, buyer, 1e16);

        vm.startPrank(buyer);
        usdtERC20.approve(address(putOption), 10e18);
        putOption.buy();

        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(putOption.buyer() == address(0), false);
        assertEq(putOption.executed(), false);
        assertEq(putOption.buyer(), buyer);

        address buyer2 = makeAddr("buyer2");

        putOption.transfer(buyer2);

        vm.stopPrank();

        assertEq(putOption.buyer(), buyer2);
    }

    function testTransferBuyerFails() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();
        vm.stopPrank();

        assertEq(putOption.inited(), true);
        assertEq(putOption.buyer() == address(0), true);

        deal(usdtToken, buyer, 10e18);
        deal(ethToken, buyer, 1e16);

        vm.startPrank(buyer);
        usdtERC20.approve(address(putOption), 10e18);
        putOption.buy();

        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(putOption.buyer() == address(0), false);
        assertEq(putOption.executed(), false);
        assertEq(putOption.buyer(), buyer);

        vm.stopPrank();

        address buyer2 = makeAddr("buyer2");

        vm.prank(buyer2);
        vm.expectRevert();
        putOption.transfer(buyer2);

        assertEq(putOption.buyer(), buyer);
    }

    function testCancel() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();

        assertEq(putOption.inited(), true);
        assertEq(putOption.executed(), false);
        assertEq(usdtERC20.balanceOf(address(putOption)), putOption.strikeValue());

        skip(5 days);
        putOption.cancel();
        vm.stopPrank();

        assertEq(putOption.executed(), true);
        assertEq(usdtERC20.balanceOf(address(putOption)), 0);
        assertEq(usdtERC20.balanceOf(creator), 38e18);
    }

    function testCancelFails() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();
        vm.stopPrank();

        assertEq(putOption.inited(), true);
        assertEq(putOption.buyer() == address(0), true);

        deal(usdtToken, buyer, 10e18);

        vm.startPrank(buyer);
        usdtERC20.approve(address(putOption), 10e18);
        putOption.buy();

        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(putOption.buyer() == address(0), false);
        assertEq(putOption.executed(), false);
        assertEq(putOption.buyer(), buyer);
        vm.stopPrank();

        vm.prank(creator);
        vm.expectRevert();
        putOption.cancel();

        assertEq(putOption.executed(), false);
        assertEq(usdtERC20.balanceOf(address(putOption)), putOption.strikeValue());
        assertEq(usdtERC20.balanceOf(creator), 10e18);
    }

    function testWithdraw() public {
        assertEq(putOption.inited(), false);
        assertEq(putOption.strikeValue(), 38e18);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption), putOption.strikeValue());
        putOption.init();
        vm.stopPrank();

        assertEq(putOption.inited(), true);
        assertEq(putOption.buyer() == address(0), true);
        assertEq(usdtERC20.balanceOf(address(putOption)), putOption.strikeValue());

        deal(usdtToken, buyer, 10e18);
        deal(ethToken, buyer, 1e16);

        vm.startPrank(buyer);
        usdtERC20.approve(address(putOption), 10e18);
        putOption.buy();
        vm.stopPrank();

        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(putOption.buyer() == address(0), false);
        assertEq(putOption.executed(), false);
        assertEq(putOption.buyer(), buyer);

        vm.warp(block.timestamp + 8 days);
        vm.prank(creator);
        putOption.withdraw();
        vm.stopPrank();

        assertEq(ethERC20.balanceOf(buyer), 1e16);
        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(usdtERC20.balanceOf(creator), 48e18);
        assertEq(putOption.executed(), true);
    }

    function testExecuteFails() public {
        uint256 _premium = 10e18;
        uint256 _strikePrice = 2000e8;
        uint256 _quantity = 1e16;
        uint256 _expiration = block.timestamp + 1 weeks;

        vm.prank(creator);
 
        PutOption putOption2 = new PutOption(ethToken, creator, _premium, _strikePrice, _quantity, _expiration, usdtToken, priceOracle);

        assertEq(putOption2.inited(), false);
        assertEq(putOption2.strikeValue(), 20e18);

        ERC20 ethERC20 = ERC20(ethToken);
        ERC20 usdtERC20 = ERC20(usdtToken);

        deal(usdtToken, creator, putOption2.strikeValue());

        vm.startPrank(creator);
        usdtERC20.approve(address(putOption2), putOption2.strikeValue());
        putOption2.init();
        vm.stopPrank();

        assertEq(usdtERC20.balanceOf(creator), 0);
        assertEq(putOption2.inited(), true);
        assertEq(putOption2.buyer() == address(0), true);

        deal(usdtToken, buyer, 10e18);
        deal(ethToken, buyer, 1e16);

        vm.startPrank(buyer);
        usdtERC20.approve(address(putOption2), 10e18);
        putOption2.buy();

        assertEq(usdtERC20.balanceOf(buyer), 0);
        assertEq(putOption2.buyer() == address(0), false);
        assertEq(putOption2.executed(), false);
        assertEq(putOption2.buyer(), buyer);

        ethERC20.approve(address(putOption2), putOption2.strikeValue());
        vm.expectRevert();
        putOption2.execute();
        vm.stopPrank();

        assertEq(ethERC20.balanceOf(buyer), 1e16);
        assertEq(usdtERC20.balanceOf(creator), 10e18);
        assertEq(putOption2.executed(), false);
    }
}
