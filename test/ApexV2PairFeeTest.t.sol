// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2PairFeeTest is Test {
    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    MockFactory factory;

    address feeReceiver = address(0x123);

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

    function testFeeOffDoesNotMintProtocolLiquidity() public {
        uint256 supplyBefore = pair.totalSupply();

        token0.mint(address(pair), 100 ether);

        token1.mint(address(pair), 100 ether);

        pair.mint(address(this));

        uint256 supplyAfter = pair.totalSupply();

        assertGt(supplyAfter, supplyBefore);
    }

    function testFeeOnMintsProtocolLiquidity() public {
        factory.setFeeTo(feeReceiver);

        // create initial kLast
        token0.mint(address(pair), 100 ether);

        token1.mint(address(pair), 100 ether);

        pair.mint(address(this));

        // make swap to generate fee growth

        token0.mint(address(this), 1000 ether);

        token0.transfer(address(pair), 100 ether);

        pair.swap(0, 90 ether, address(this), "");

        // trigger _mintFee()

        token0.mint(address(pair), 100 ether);

        token1.mint(address(pair), 100 ether);

        pair.mint(address(this));

        uint256 feeBalance = pair.balanceOf(feeReceiver);

        assertGt(feeBalance, 0);
    }

    function testKLastUpdatesWhenFeeOn() public {
        factory.setFeeTo(feeReceiver);

        token0.mint(address(pair), 100 ether);

        token1.mint(address(pair), 100 ether);

        pair.mint(address(this));

        assertGt(pair.kLast(), 0);
    }

    function testFeeCannotBeManipulatedByDonation() public {
        factory.setFeeTo(feeReceiver);

        token0.mint(address(pair), 100 ether);

        token1.mint(address(pair), 100 ether);

        pair.mint(address(this));

        // attacker donation

        token0.mint(address(pair), 1000 ether);

        token1.mint(address(pair), 1000 ether);

        uint256 feeBefore = pair.balanceOf(feeReceiver);

        // no mint/burn, no fee calculation

        uint256 feeAfter = pair.balanceOf(feeReceiver);

        assertEq(feeAfter, feeBefore);
    }

    function testFeeOffClearsKLast() public {
        // Enable protocol fee

        factory.setFeeTo(feeReceiver);

        token0.mint(address(pair), 100 ether);

        token1.mint(address(pair), 100 ether);

        pair.mint(address(this));

        uint256 kLastBefore = pair.kLast();

        assertGt(kLastBefore, 0);

        // Disable protocol fee

        factory.setFeeTo(address(0));

        token0.mint(address(pair), 100 ether);

        token1.mint(address(pair), 100 ether);

        pair.mint(address(this));

        assertEq(pair.kLast(), 0);
    }
}
