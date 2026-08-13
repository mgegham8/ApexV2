// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2PairGriefingTest is Test {
    ApexV2Factory factory;
    ApexV2Router router;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;
    MockERC20 weth;

    function setUp() public {
        MockERC20 tokenA = new MockERC20("Token0", "TK0");
        MockERC20 tokenB = new MockERC20("Token1", "TK1");
        if (address(tokenA) < address(tokenB)) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }

        weth = new MockERC20("WETH", "WETH");
        factory = new ApexV2Factory(address(this));
        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));
        router = new ApexV2Router(address(factory), address(weth));
    }

    function testFirstLiquidityMinimumLockingGriefing() public {
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);

        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);

        router.addLiquidity(
            address(token0),
            address(token1),
            amount0,
            amount1,
            0,
            0,
            address(this),
            block.timestamp
        );

        assertEq(pair.balanceOf(address(0)), 1000, "Minimum liquidity not locked correctly");
        assertTrue(pair.balanceOf(address(this)) > 0, "Attacker did not receive LP tokens");
    }

    function testDustAttackAndTinySwapSpam() public {
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);

        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);

        router.addLiquidity(
            address(token0),
            address(token1),
            amount0,
            amount1,
            0,
            0,
            address(this),
            block.timestamp
        );

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        for (uint256 i = 0; i < 10; i++) {
            uint256 tinyAmount = 1 wei;
            token0.mint(address(this), tinyAmount);
            token0.approve(address(router), tinyAmount);

            try router.swapExactTokensForTokens(
                tinyAmount,
                0,
                path,
                address(this),
                block.timestamp
            ) {} catch {}
        }

        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertTrue(r0 > 0 && r1 > 0, "Reserves corrupted by tiny spam");
    }
}