// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2PairOracleSecurityTest is Test {
    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    MockFactory factory;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        factory = new MockFactory();

        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));

        token0.mint(address(this), 10000 ether);

        token1.mint(address(this), 10000 ether);

        token0.transfer(address(pair), 1000 ether);

        token1.transfer(address(pair), 1000 ether);

        pair.mint(address(this));
    }

    function testPriceCumulativeUpdatesAfterTimePasses() public {
        vm.warp(block.timestamp + 1 hours);

        token0.mint(address(pair), 100 ether);

        token1.mint(address(pair), 100 ether);

        pair.sync();

        uint256 price0 = pair.price0CumulativeLast();

        uint256 price1 = pair.price1CumulativeLast();

        assertGt(price0, 0);

        assertGt(price1, 0);
    }

    function testNoOracleUpdateWithoutTimeElapsed() public {
        uint256 price0Before = pair.price0CumulativeLast();

        uint256 price1Before = pair.price1CumulativeLast();

        pair.sync();

        uint256 price0After = pair.price0CumulativeLast();

        uint256 price1After = pair.price1CumulativeLast();

        assertEq(price0After, price0Before);

        assertEq(price1After, price1Before);
    }

    function testReserveTimestampUpdatesCorrectly() public {
        (,, uint32 timestampBefore) = pair.getReserves();

        vm.warp(block.timestamp + 500);

        pair.sync();

        (,, uint32 timestampAfter) = pair.getReserves();

        assertGt(timestampAfter, timestampBefore);
    }

    function testOracleTimestampOverflowSafety() public {
        vm.warp(uint256(type(uint32).max) + 100);

        pair.sync();

        (,, uint32 timestamp) = pair.getReserves();

        assertEq(timestamp, uint32(block.timestamp));
    }
}
