// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../interfaces/IApexV2Factory.sol";
import "../interfaces/IApexV2Pair.sol";

library ApexV2Library {
    // ============================================================
    // SORT TOKENS
    // ============================================================

    function sortTokens(
        address tokenA,
        address tokenB
    )
        internal
        pure
        returns (
            address token0,
            address token1
        )
    {
        require(
            tokenA != tokenB,
            "IDENTICAL_ADDRESSES"
        );

        require(
            tokenA != address(0) &&
                tokenB != address(0),
            "ZERO_ADDRESS"
        );

        (
            token0,
            token1
        ) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    // ============================================================
    // PAIR LOOKUP
    // ============================================================

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (address pair)
    {
        require(
            factory != address(0),
            "ZERO_FACTORY"
        );

        sortTokens(
            tokenA,
            tokenB
        );

        pair =
            IApexV2Factory(factory).getPair(
                tokenA,
                tokenB
            );

        require(
            pair != address(0),
            "PAIR_NOT_FOUND"
        );
    }

    // ============================================================
    // RESERVES
    // ============================================================

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB
        )
    {
        (
            address token0,
        ) =
            sortTokens(
                tokenA,
                tokenB
            );

        address pair =
            pairFor(
                factory,
                tokenA,
                tokenB
            );

        (
            uint112 reserve0,
            uint112 reserve1,
        ) =
            IApexV2Pair(pair).getReserves();

        if (tokenA == token0) {
            reserveA =
                uint256(reserve0);

            reserveB =
                uint256(reserve1);
        } else {
            reserveA =
                uint256(reserve1);

            reserveB =
                uint256(reserve0);
        }
    }

    // ============================================================
    // QUOTE
    // ============================================================

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    )
        internal
        pure
        returns (uint256 amountB)
    {
        require(
            amountA > 0,
            "INSUFFICIENT_AMOUNT"
        );

        require(
            reserveA > 0 &&
                reserveB > 0,
            "INSUFFICIENT_LIQUIDITY"
        );

        require(
            amountA <=
                type(uint256).max /
                    reserveB,
            "AMOUNT_OVERFLOW"
        );

        amountB =
            (
                amountA *
                    reserveB
            ) /
                reserveA;
    }

    // ============================================================
    // AMOUNT OUT
    // ============================================================

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        internal
        pure
        returns (uint256 amountOut)
    {
        require(
            amountIn > 0,
            "INSUFFICIENT_INPUT"
        );

        require(
            reserveIn > 0 &&
                reserveOut > 0,
            "INSUFFICIENT_LIQUIDITY"
        );

        // amountIn * 997
        require(
            amountIn <=
                type(uint256).max /
                    997,
            "AMOUNT_OVERFLOW"
        );

        uint256 amountInWithFee =
            amountIn *
                997;

        // amountInWithFee * reserveOut
        require(
            reserveOut <=
                type(uint256).max /
                    amountInWithFee,
            "AMOUNT_OVERFLOW"
        );

        uint256 numerator =
            amountInWithFee *
                reserveOut;

        // reserveIn * 1000
        require(
            reserveIn <=
                type(uint256).max /
                    1000,
            "RESERVE_OVERFLOW"
        );

        uint256 scaledReserveIn =
            reserveIn *
                1000;

        // scaledReserveIn + amountInWithFee
        require(
            scaledReserveIn <=
                type(uint256).max -
                    amountInWithFee,
            "AMOUNT_OVERFLOW"
        );

        uint256 denominator =
            scaledReserveIn +
                amountInWithFee;

        amountOut =
            numerator /
                denominator;
    }

    // ============================================================
    // MULTI-HOP AMOUNTS OUT
    // ============================================================

    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    )
        internal
        view
        returns (
            uint256[] memory amounts
        )
    {
        require(
            factory != address(0),
            "ZERO_FACTORY"
        );

        require(
            amountIn > 0,
            "INSUFFICIENT_INPUT"
        );

        require(
            path.length >= 2,
            "INVALID_PATH"
        );

        uint256 pathLength =
            path.length;

        amounts =
            new uint256[](
                pathLength
            );

        amounts[0] =
            amountIn;

        for (
            uint256 i;
            i < pathLength - 1;
        ) {
            address input =
                path[i];

            address output =
                path[i + 1];

            require(
                input != address(0) &&
                    output != address(0),
                "ZERO_ADDRESS"
            );

            require(
                input != output,
                "IDENTICAL_ADDRESSES"
            );

            (
                uint256 reserveIn,
                uint256 reserveOut
            ) =
                getReserves(
                    factory,
                    input,
                    output
                );

            amounts[i + 1] =
                getAmountOut(
                    amounts[i],
                    reserveIn,
                    reserveOut
                );

            unchecked {
                ++i;
            }
        }
    }

    // ============================================================
    // LIQUIDITY AMOUNTS
    // ============================================================

    function getAmountsForLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        internal
        view
        returns (
            uint256 amountA,
            uint256 amountB
        )
    {
        require(
            factory != address(0),
            "ZERO_FACTORY"
        );

        sortTokens(
            tokenA,
            tokenB
        );

        require(
            amountADesired > 0,
            "INSUFFICIENT_A"
        );

        require(
            amountBDesired > 0,
            "INSUFFICIENT_B"
        );

        address pair =
            IApexV2Factory(factory).getPair(
                tokenA,
                tokenB
            );

        if (pair == address(0)) {
            return (
                amountADesired,
                amountBDesired
            );
        }

        (
            uint256 reserveA,
            uint256 reserveB
        ) =
            getReserves(
                factory,
                tokenA,
                tokenB
            );

        if (
            reserveA == 0 &&
            reserveB == 0
        ) {
            return (
                amountADesired,
                amountBDesired
            );
        }

        require(
            reserveA > 0 &&
                reserveB > 0,
            "INVALID_RESERVES"
        );

        uint256 amountBOptimal =
            quote(
                amountADesired,
                reserveA,
                reserveB
            );

        if (
            amountBOptimal <=
                amountBDesired
        ) {
            amountA =
                amountADesired;

            amountB =
                amountBOptimal;
        } else {
            uint256 amountAOptimal =
                quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );

            require(
                amountAOptimal <=
                    amountADesired,
                "EXCESSIVE_A"
            );

            amountA =
                amountAOptimal;

            amountB =
                amountBDesired;
        }
    }
}