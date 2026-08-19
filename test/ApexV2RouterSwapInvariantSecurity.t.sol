// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2RouterSwapInvariantSecurityTest is Test {
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

        token0.mint(address(this), 100000 ether);

        token1.mint(address(this), 100000 ether);

        token0.approve(address(router), type(uint256).max);

        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(
            address(token0), address(token1), 50000 ether, 50000 ether, 0, 0, address(this), block.timestamp + 1 hours
        );
    }

    function testSwapCannotBreakKInvariant() public {
        (uint256 reserve0Before, uint256 reserve1Before) = getReserves();

        uint256 kBefore = reserve0Before * reserve1Before;

        address[] memory path = new address[](2);

        path[0] = address(token0);
        path[1] = address(token1);

        router.swapExactTokensForTokens(1000 ether, 1 ether, path, address(this), block.timestamp + 1 hours);

        (uint256 reserve0After, uint256 reserve1After) = getReserves();

        uint256 kAfter = reserve0After * reserve1After;

        assertGe(kAfter, kBefore);
    }

    function testHugeSwapCannotDrainPool() public {
        address[] memory path = new address[](2);

        path[0] = address(token0);
        path[1] = address(token1);

        vm.expectRevert();

        router.swapExactTokensForTokens(90000 ether, 1 ether, path, address(this), block.timestamp + 1 hours);
    }

    function getReserves() internal view returns (uint256 reserve0, uint256 reserve1) {
        (uint112 r0, uint112 r1, uint32 timestampLast) = pair.getReserves();

        reserve0 = uint256(r0);
        reserve1 = uint256(r1);

        // use timestamp to avoid compiler warning
        timestampLast;
    }
}
