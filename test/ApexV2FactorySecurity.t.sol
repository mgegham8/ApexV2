// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2FactorySecurityTest is Test {
    ApexV2Factory factory;

    MockERC20 tokenA;
    MockERC20 tokenB;

    function setUp() public {
        factory = new ApexV2Factory(address(this));

        tokenA = new MockERC20("Token A", "TKA");

        tokenB = new MockERC20("Token B", "TKB");
    }

    function testCreatePairWorks() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));

        assertTrue(pair != address(0));

        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
    }

    function testCannotCreateSamePairTwice() public {
        factory.createPair(address(tokenA), address(tokenB));

        vm.expectRevert();

        factory.createPair(address(tokenA), address(tokenB));
    }

    function testPairOrderIsSorted() public {
        address pair = factory.createPair(address(tokenB), address(tokenA));

        ApexV2Pair p = ApexV2Pair(pair);

        assertEq(p.token0(), address(tokenA));

        assertEq(p.token1(), address(tokenB));
    }

    function testGetPairBothDirections() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));

        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);

        assertEq(factory.getPair(address(tokenB), address(tokenA)), pair);
    }

    function testCannotCreatePairWithSameToken() public {
        vm.expectRevert();

        factory.createPair(address(tokenA), address(tokenA));
    }

    function testCannotCreatePairZeroAddress() public {
        vm.expectRevert();

        factory.createPair(address(0), address(tokenA));
    }
}
