// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../../src/contracts/ApexV2Pair.sol";
import "../../src/contracts/test/MockERC20.sol";

contract ApexV2PairHandler is Test {
    ApexV2Pair public pair;

    MockERC20 public token0;
    MockERC20 public token1;

    uint256 public addLiquidityCalls;
    uint256 public removeLiquidityCalls;
    uint256 public swapCalls;
    uint256 public donationCalls;
    uint256 public syncCalls;
    uint256 public skimCalls;

    bool public swapInvariantBroken;

    uint256 private constant INITIAL_LIQUIDITY =
        1_000 ether;

    uint256 private constant MIN_ACTION_AMOUNT =
        1e6;

    uint256 private constant MAX_ACTION_AMOUNT =
        100 ether;

    constructor(
        ApexV2Pair _pair,
        MockERC20 _token0,
        MockERC20 _token1
    ) {
        pair = _pair;
        token0 = _token0;
        token1 = _token1;

        /*
         * Initialize the pool deterministically before invariant
         * fuzzing starts.
         *
         * This guarantees:
         * - totalSupply > MINIMUM_LIQUIDITY
         * - non-zero reserves
         * - handler owns usable LP tokens
         */
        token0.mint(
            address(this),
            INITIAL_LIQUIDITY
        );

        token1.mint(
            address(this),
            INITIAL_LIQUIDITY
        );

        bool success0 =
            token0.transfer(
                address(pair),
                INITIAL_LIQUIDITY
            );

        bool success1 =
            token1.transfer(
                address(pair),
                INITIAL_LIQUIDITY
            );

        require(
            success0 && success1,
            "INITIAL_TRANSFER_FAILED"
        );

        pair.mint(
            address(this)
        );
    }

    // ============================================================
    // ADD LIQUIDITY
    // ============================================================

    function addLiquidity(
        uint256 seed
    )
        external
    {
        (
            uint112 reserve0,
            uint112 reserve1,
        ) =
            pair.getReserves();

        if (
            reserve0 == 0 ||
            reserve1 == 0
        ) {
            return;
        }

        uint256 amount0 =
            bound(
                seed,
                MIN_ACTION_AMOUNT,
                MAX_ACTION_AMOUNT
            );

        /*
         * Add liquidity at the current pool ratio.
         *
         * Random independent amount0/amount1 values can result in
         * one side contributing effectively zero LP because of
         * integer rounding.
         */
        uint256 amount1 =
            (
                amount0 *
                    uint256(reserve1)
            ) /
                uint256(reserve0);

        if (amount1 == 0) {
            return;
        }

        uint256 pairBalance0 =
            token0.balanceOf(
                address(pair)
            );

        uint256 pairBalance1 =
            token1.balanceOf(
                address(pair)
            );

        /*
         * Pair reserves are uint112.
         * Avoid intentionally driving _update() into Overflow().
         */
        if (
            pairBalance0 >
                type(uint112).max ||
            pairBalance1 >
                type(uint112).max
        ) {
            return;
        }

        if (
            amount0 >
                type(uint112).max -
                    pairBalance0 ||
            amount1 >
                type(uint112).max -
                    pairBalance1
        ) {
            return;
        }

        token0.mint(
            address(this),
            amount0
        );

        token1.mint(
            address(this),
            amount1
        );

        bool success0 =
            token0.transfer(
                address(pair),
                amount0
            );

        bool success1 =
            token1.transfer(
                address(pair),
                amount1
            );

        require(
            success0 && success1,
            "ADD_TRANSFER_FAILED"
        );

        uint256 liquidity =
            pair.mint(
                address(this)
            );

        require(
            liquidity > 0,
            "ZERO_LIQUIDITY"
        );

        unchecked {
            ++addLiquidityCalls;
        }
    }

    // ============================================================
    // REMOVE LIQUIDITY
    // ============================================================

    function removeLiquidity(
        uint256 seed
    )
        external
    {
        uint256 balance =
            pair.balanceOf(
                address(this)
            );

        if (balance == 0) {
            return;
        }

        uint256 liquidity =
            bound(
                seed,
                1,
                balance
            );

        bool transferred =
            pair.transfer(
                address(pair),
                liquidity
            );

        require(
            transferred,
            "LP_TRANSFER_FAILED"
        );

        (
            uint256 amount0,
            uint256 amount1
        ) =
            pair.burn(
                address(this)
            );

        require(
            amount0 > 0 &&
                amount1 > 0,
            "ZERO_BURN_OUTPUT"
        );

        unchecked {
            ++removeLiquidityCalls;
        }
    }

    // ============================================================
    // SWAP TOKEN0 -> TOKEN1
    // ============================================================

    function swap(
        uint256 seed
    )
        external
    {
        (
            uint112 reserve0,
            uint112 reserve1,
        ) =
            pair.getReserves();

        /*
         * Prevent invalid bound(min, max) when the pool becomes very
         * small after liquidity removals.
         */
        if (
            reserve0 <=
                MIN_ACTION_AMOUNT * 5 ||
            reserve1 == 0
        ) {
            return;
        }

        uint256 maxAmountIn =
            uint256(reserve0) /
                5;

        if (
            maxAmountIn <
                MIN_ACTION_AMOUNT
        ) {
            return;
        }

        uint256 amount0In =
            bound(
                seed,
                MIN_ACTION_AMOUNT,
                maxAmountIn
            );

        uint256 amountInWithFee =
            amount0In *
                997;

        uint256 numerator =
            amountInWithFee *
                uint256(reserve1);

        uint256 denominator =
            uint256(reserve0) *
                1000 +
                amountInWithFee;

        uint256 amount1Out =
            numerator /
                denominator;

        if (
            amount1Out == 0 ||
            amount1Out >= reserve1
        ) {
            return;
        }

        uint256 kBefore =
            uint256(reserve0) *
                uint256(reserve1);

        token0.mint(
            address(this),
            amount0In
        );

        bool transferred =
            token0.transfer(
                address(pair),
                amount0In
            );

        require(
            transferred,
            "SWAP_TRANSFER_FAILED"
        );

        pair.swap(
            0,
            amount1Out,
            address(this),
            bytes("")
        );

        (
            uint112 reserve0After,
            uint112 reserve1After,
        ) =
            pair.getReserves();

        uint256 kAfter =
            uint256(reserve0After) *
                uint256(reserve1After);

        /*
         * Swap must never reduce K.
         *
         * Do not revert here: invariant fuzzing tolerates target
         * reverts. Record the violation so the invariant itself
         * fails deterministically.
         */
        if (kAfter < kBefore) {
            swapInvariantBroken = true;
        }

        unchecked {
            ++swapCalls;
        }
    }

    // ============================================================
    // DONATION
    // ============================================================

    function donation(
        uint256 seed0,
        uint256 seed1
    )
        external
    {
        uint256 amount0 =
            bound(
                seed0,
                1,
                MAX_ACTION_AMOUNT
            );

        uint256 amount1 =
            bound(
                seed1,
                1,
                MAX_ACTION_AMOUNT
            );

        token0.mint(
            address(this),
            amount0
        );

        token1.mint(
            address(this),
            amount1
        );

        bool success0 =
            token0.transfer(
                address(pair),
                amount0
            );

        bool success1 =
            token1.transfer(
                address(pair),
                amount1
            );

        require(
            success0 && success1,
            "DONATION_TRANSFER_FAILED"
        );

        unchecked {
            ++donationCalls;
        }
    }

    // ============================================================
    // SYNC
    // ============================================================

    function sync()
        external
    {
        uint256 balance0 =
            token0.balanceOf(
                address(pair)
            );

        uint256 balance1 =
            token1.balanceOf(
                address(pair)
            );

        if (
            balance0 >
                type(uint112).max ||
            balance1 >
                type(uint112).max
        ) {
            return;
        }

        pair.sync();

        unchecked {
            ++syncCalls;
        }
    }

    // ============================================================
    // SKIM
    // ============================================================

    function skim()
        external
    {
        pair.skim(
            address(this)
        );

        unchecked {
            ++skimCalls;
        }
    }
}