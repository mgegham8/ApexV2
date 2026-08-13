// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract MockBadRouter {


    function addLiquidity(
        address,
        address,
        uint,
        uint,
        uint,
        uint,
        address,
        uint
    )
    external
    payable
    returns(
        uint,
        uint,
        uint
    )
    {

        return (
            0,
            0,
            0
        );

    }


}