// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2EconomicAttackTest is Test {
    ApexV2Factory factory;
    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    address attacker = address(100);
    address user = address(200);

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        factory = new ApexV2Factory(address(this));

        address pairAddress = factory.createPair(address(token0), address(token1));

        pair = ApexV2Pair(pairAddress);

        token0.mint(address(this), 100000 ether);

        token1.mint(address(this), 100000 ether);

        token0.transfer(address(pair), 10000 ether);

        token1.transfer(address(pair), 10000 ether);

        pair.mint(address(this));
    }

    /*
        Attack 1:

        Direct donation must not change reserves
    */
    function testDonationCannotCreateProfit() public {
        uint256 balanceBefore = token0.balanceOf(attacker);

        token0.mint(attacker, 1000 ether);

        vm.prank(attacker);

        token0.transfer(address(pair), 1000 ether);

        (uint112 r0, uint112 r1,) = pair.getReserves();

        assertEq(r0, 10000 ether);

        assertEq(r1, 10000 ether);

        assertEq(token0.balanceOf(attacker), 0);

        assertEq(balanceBefore, 0);
    }

    /*
        Attack 2:

        Attacker cannot burn liquidity
        he does not own
    */
    function testLiquidityDrainImpossible() public {
        uint256 lp = pair.balanceOf(address(this));

        vm.prank(attacker);

        vm.expectRevert();

        pair.transfer(address(pair), lp);
    }

    /*
        Attack 3:

        Tiny liquidity cannot create free LP tokens
    */
    function testTinyLiquidityCannotGenerateFreeTokens() public {
        MockERC20 a = new MockERC20("A", "A");

        MockERC20 b = new MockERC20("B", "B");

        address p = factory.createPair(address(a), address(b));

        ApexV2Pair tinyPair = ApexV2Pair(p);

        a.mint(address(this), 1000);

        b.mint(address(this), 1000);

        a.transfer(address(tinyPair), 1000);

        b.transfer(address(tinyPair), 1000);

        vm.expectRevert();

        tinyPair.mint(address(this));
    }

    /*
        Attack 4:

        Attacker cannot break K invariant
    */
    function testAttackerCannotBreakK() public {
        (uint112 r0, uint112 r1,) = pair.getReserves();

        uint256 oldK = uint256(r0) * uint256(r1);

        vm.prank(attacker);

        vm.expectRevert();

        pair.swap(1000 ether, 0, attacker, "");

        (uint112 nr0, uint112 nr1,) = pair.getReserves();

        uint256 newK = uint256(nr0) * uint256(nr1);

        assertGe(newK, oldK);
    }
}
