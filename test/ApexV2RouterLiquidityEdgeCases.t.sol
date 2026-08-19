// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2RouterLiquidityEdgeCasesTest is Test {
    ApexV2Factory factory;
    ApexV2Router router;
    MockERC20 weth;
    MockERC20 tokenA;
    MockERC20 tokenB;

    address user = address(0xA11cE);

    function setUp() public {
        factory = new ApexV2Factory(address(this));

        weth = new MockERC20("Wrapped Ether", "WETH");
        router = new ApexV2Router(address(factory), address(weth));

        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");

        tokenA.mint(user, 1000e18);
        tokenB.mint(user, 1000e18);

        vm.startPrank(user);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        vm.stopPrank();

        factory.createPair(address(tokenA), address(tokenB));
    }

    function test_RevertWhen_AddLiquidity_ExpiredDeadline() public {
        vm.startPrank(user);
        vm.warp(1000);

        vm.expectRevert();
        router.addLiquidity(address(tokenA), address(tokenB), 100e18, 100e18, 1, 1, user, 999);
        vm.stopPrank();
    }

    function test_RevertWhen_AddLiquidity_ZeroAmounts() public {
        vm.startPrank(user);
        vm.expectRevert();
        router.addLiquidity(address(tokenA), address(tokenB), 0, 0, 0, 0, user, block.timestamp + 100);
        vm.stopPrank();
    }

    function test_RevertWhen_RemoveLiquidity_ExpiredDeadline() public {
        vm.startPrank(user);
        vm.warp(1000);

        vm.expectRevert();
        router.removeLiquidity(address(tokenA), address(tokenB), 100, 1, 1, user, 999);
        vm.stopPrank();
    }
}
