// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract MockRouter {


    function addLiquidity(
        address,
        address,
        uint amountADesired,
        uint amountBDesired,
        uint,
        uint,
        address,
        uint
    )
    external
    payable
    returns(
        uint amountA,
        uint amountB,
        uint liquidity
    )
    {

        amountA = amountADesired;

        amountB = amountBDesired;

        liquidity = 100 ether;


    }


}