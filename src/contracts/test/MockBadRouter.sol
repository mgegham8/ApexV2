// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract MockBadRouter {
    function addLiquidityETH(address, uint256, uint256, uint256, address, uint256)
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        return (0, 0, 0);
    }
}
