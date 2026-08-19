// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract MockRouter {
    function addLiquidityETH(
        address,
        uint256 amountTokenDesired,
        uint256,
        uint256,
        address,
        uint256
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        amountToken =
            amountTokenDesired;

        amountETH =
            msg.value;

        liquidity =
            100 ether;
    }
}