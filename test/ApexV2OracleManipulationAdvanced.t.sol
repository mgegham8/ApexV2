// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2OracleManipulationAdvancedTest is Test {
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

        token0.mint(address(this), 1000 ether);

        token1.mint(address(this), 1000 ether);

        token0.transfer(address(pair), 1000 ether);

        token1.transfer(address(pair), 1000 ether);

        pair.mint(address(this));
    }

    function testFlashLoanAndSwapSameBlockOracleManipulation() public {
        uint256 initialPriceCumulative = pair.price0CumulativeLast();

        token0.mint(address(this), 5000 ether);

        token0.transfer(address(pair), 5000 ether);

        pair.swap(0, 800 ether, address(this), "");

        uint256 priceCumulativeAfterSameBlock = pair.price0CumulativeLast();

        assertEq(
            initialPriceCumulative, priceCumulativeAfterSameBlock, "Cumulative price changed within the same block"
        );

        warpToNextBlock(1 hours);

        pair.sync();

        uint256 priceCumulativeAfterTime = pair.price0CumulativeLast();

        assertTrue(
            priceCumulativeAfterTime > initialPriceCumulative, "Oracle failed to accumulate price after time passed"
        );
    }

    function warpToNextBlock(uint256 timeDelta) internal {
        vm.warp(block.timestamp + timeDelta);

        vm.roll(block.number + 1);
    }
}
