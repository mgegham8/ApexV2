// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


/**
 * @notice Binary fixed point arithmetic library
 * @dev Uses UQ112x112 format
 */
library UQ112x112 {


    uint224 internal constant Q112 =
        2 ** 112;




    /**
     * @notice Encode uint112 into UQ112x112
     */
    function encode(
        uint112 y
    )
        internal
        pure
        returns(uint224 z)
    {

        z =
            uint224(y)
            *
            Q112;

    }





    /**
     * @notice Divide UQ112x112 number by uint112
     */
    function uqdiv(
        uint224 x,
        uint112 y
    )
        internal
        pure
        returns(uint224 z)
    {

        require(
            y != 0,
            "UQ112x112: DIV_BY_ZERO"
        );


        z =
            x /
            uint224(y);

    }

}