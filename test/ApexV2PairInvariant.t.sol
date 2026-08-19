// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";

import "./handlers/ApexV2PairHandler.sol";

contract ApexV2PairInvariantTest is Test {
    ApexV2Factory public factory;
    ApexV2Pair public pair;

    MockERC20 public token0;
    MockERC20 public token1;

    ApexV2PairHandler public handler;

    function setUp()
        public
    {
        MockERC20 tokenA =
            new MockERC20(
                "TokenA",
                "TKA"
            );

        MockERC20 tokenB =
            new MockERC20(
                "TokenB",
                "TKB"
            );

        factory =
            new ApexV2Factory(
                address(this)
            );

        address pairAddress =
            factory.createPair(
                address(tokenA),
                address(tokenB)
            );

        pair =
            ApexV2Pair(
                pairAddress
            );

        /*
         * Handler token references MUST follow the Pair's canonical
         * token0/token1 ordering.
         */
        if (
            pair.token0() ==
            address(tokenA)
        ) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }

        handler =
            new ApexV2PairHandler(
                pair,
                token0,
                token1
            );

        targetContract(
            address(handler)
        );
    }

    // ============================================================
    // RESERVES <= BALANCES
    // ============================================================

    function invariant_reserves_not_bigger_than_balances()
        public
        view
    {
        (
            uint112 reserve0,
            uint112 reserve1,
        ) =
            pair.getReserves();

        uint256 balance0 =
            token0.balanceOf(
                address(pair)
            );

        uint256 balance1 =
            token1.balanceOf(
                address(pair)
            );

        assertLe(
            uint256(reserve0),
            balance0
        );

        assertLe(
            uint256(reserve1),
            balance1
        );
    }

    // ============================================================
    // UINT112 RESERVE BOUNDS
    // ============================================================

    function invariant_reserves_uint112()
        public
        view
    {
        (
            uint112 reserve0,
            uint112 reserve1,
        ) =
            pair.getReserves();

        assertLe(
            uint256(reserve0),
            uint256(type(uint112).max)
        );

        assertLe(
            uint256(reserve1),
            uint256(type(uint112).max)
        );
    }

    // ============================================================
    // SWAP K INVARIANT
    // ============================================================

    function invariant_swaps_never_decrease_k()
        public
        view
    {
        assertFalse(
            handler.swapInvariantBroken(),
            "SWAP_K_DECREASED"
        );
    }

    // ============================================================
    // MINIMUM LIQUIDITY LOCK
    // ============================================================

    function invariant_minimum_liquidity_remains_locked()
        public
        view
    {
        uint256 minimumLiquidity =
            pair.MINIMUM_LIQUIDITY();

        assertEq(
            pair.balanceOf(
                address(0)
            ),
            minimumLiquidity
        );

        assertGe(
            pair.totalSupply(),
            minimumLiquidity
        );
    }

    // ============================================================
    // TOTAL SUPPLY
    // ============================================================

    function invariant_total_supply_valid()
        public
        view
    {
        assertGe(
            pair.totalSupply(),
            pair.MINIMUM_LIQUIDITY()
        );
    }

    // ============================================================
    // DONATION ACCOUNTING
    // ============================================================

    function invariant_donation_accounting_safe()
        public
        view
    {
        (
            uint112 reserve0,
            uint112 reserve1,
        ) =
            pair.getReserves();

        uint256 balance0 =
            token0.balanceOf(
                address(pair)
            );

        uint256 balance1 =
            token1.balanceOf(
                address(pair)
            );

        assertGe(
            balance0,
            uint256(reserve0)
        );

        assertGe(
            balance1,
            uint256(reserve1)
        );
    }

    // ============================================================
    // TOKEN IMMUTABILITY
    // ============================================================

    function invariant_tokens_never_change()
        public
        view
    {
        assertEq(
            pair.token0(),
            address(token0)
        );

        assertEq(
            pair.token1(),
            address(token1)
        );
    }

    // ============================================================
    // HANDLER STATE
    // ============================================================

    function invariant_handler_state_valid()
        public
        view
    {
        assertFalse(
            handler.swapInvariantBroken()
        );
    }
}