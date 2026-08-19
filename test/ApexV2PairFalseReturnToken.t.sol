// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/FalseReturnERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2PairFalseReturnTokenTest is Test {
    ApexV2Pair pair;

    FalseReturnERC20 token0;
    FalseReturnERC20 token1;

    MockFactory factory;

    function setUp() public {
        factory = new MockFactory();

        token0 = new FalseReturnERC20();
        token1 = new FalseReturnERC20();

        pair = new ApexV2Pair();

        pair.initialize(address(token0), address(token1));

        token0.mint(address(this), 1000 ether);

        token1.mint(address(this), 1000 ether);
    }

    function testFalseReturnTokenIsRejected() public {
        bool ok0 = token0.transfer(address(pair), 100 ether);

        bool ok1 = token1.transfer(address(pair), 100 ether);

        console.log("token0 transfer returned", ok0);

        console.log("token1 transfer returned", ok1);

        assertFalse(ok0);
        assertFalse(ok1);

        console.log("pair token0 balance", token0.balanceOf(address(pair)));

        console.log("pair token1 balance", token1.balanceOf(address(pair)));

        vm.expectRevert();

        pair.mint(address(this));
    }
}
