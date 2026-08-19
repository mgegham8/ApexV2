// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

library UQ112x112 {
    error DivisionByZero();

    uint224 internal constant Q112 =
        uint224(1) << 112;

    function encode(
        uint112 y
    )
        internal
        pure
        returns (uint224 z)
    {
        z =
            uint224(y) *
            Q112;
    }

    function uqdiv(
        uint224 x,
        uint112 y
    )
        internal
        pure
        returns (uint224 z)
    {
        if (y == 0) {
            revert DivisionByZero();
        }

        z =
            x /
            uint224(y);
    }
}