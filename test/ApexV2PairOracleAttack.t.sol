// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2PairOracleAttackTest is Test {
    ApexV2Factory factory;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;

    function setUp() public {
        // Pass fee setter address (e.g., address(this)) to the factory constructor
        factory = new ApexV2Factory(address(this));

        MockERC20 tokenA = new MockERC20("Token0", "TK0");
        MockERC20 tokenB = new MockERC20("Token1", "TK1");

        // Create pair through factory to pass initialize restrictions
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));
        pair = ApexV2Pair(pairAddress);

        // Assign sorted references for test interactions
        if (address(tokenA) < address(tokenB)) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }

        token0.mint(address(this), 10000 ether);
        token1.mint(address(this), 10000 ether);

        token0.transfer(address(pair), 5000 ether);
        token1.transfer(address(pair), 5000 ether);

        pair.mint(address(this));
    }

    function testOracleCannotChangeWithoutTime() public {
        uint256 price0Before = pair.price0CumulativeLast();
        uint256 price1Before = pair.price1CumulativeLast();

        (,, uint32 timestampBefore) = pair.getReserves();

        pair.sync();

        uint256 price0After = pair.price0CumulativeLast();
        uint256 price1After = pair.price1CumulativeLast();

        (,, uint32 timestampAfter) = pair.getReserves();

        assertEq(price0Before, price0After);
        assertEq(price1Before, price1After);
        assertEq(timestampBefore, timestampAfter);
    }

    function testOracleUpdatesAfterTimePasses() public {
        uint256 price0Before = pair.price0CumulativeLast();
        uint256 price1Before = pair.price1CumulativeLast();

        vm.warp(block.timestamp + 1 hours);

        pair.sync();

        uint256 price0After = pair.price0CumulativeLast();
        uint256 price1After = pair.price1CumulativeLast();

        assertGt(price0After, price0Before);
        assertGt(price1After, price1Before);
    }
}
