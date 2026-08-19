// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2RouterSwapSecurityTest is Test {
    ApexV2Router router;

    MockFactory factory;

    MockERC20 token0;
    MockERC20 token1;

    ApexV2Pair pair;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        factory = new MockFactory();

        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));

        router = new ApexV2Router(address(factory), address(0x123));

        token0.mint(address(this), 10000 ether);

        token1.mint(address(this), 10000 ether);

        token0.approve(address(router), type(uint256).max);

        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(
            address(token0), address(token1), 5000 ether, 5000 ether, 0, 0, address(this), block.timestamp + 1 hours
        );
    }

    function testSwapWorks() public {
        address[] memory path = new address[](2);

        path[0] = address(token0);
        path[1] = address(token1);

        uint256[] memory amounts =
            router.swapExactTokensForTokens(100 ether, 1 ether, path, address(this), block.timestamp + 1 hours);

        assertGt(amounts[1], 0);

        (uint256 reserve0, uint256 reserve1, uint256 timestamp) = pair.getReserves();

        assertGt(reserve0, 0);

        assertGt(reserve1, 0);

        assertGt(timestamp, 0);
    }

    function testSwapSlippageFails() public {
        address[] memory path = new address[](2);

        path[0] = address(token0);
        path[1] = address(token1);

        vm.expectRevert();

        router.swapExactTokensForTokens(100 ether, 10000 ether, path, address(this), block.timestamp + 1 hours);
    }

    function testInvalidPathFails() public {
        address[] memory path = new address[](1);

        path[0] = address(token0);

        vm.expectRevert();

        router.swapExactTokensForTokens(100 ether, 0, path, address(this), block.timestamp + 1 hours);
    }
}
