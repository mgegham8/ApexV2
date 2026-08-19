// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract FakePair {
    bool public attacked;

    address public token0;
    address public token1;

    constructor(address _token0, address _token1) {
        token0 = _token0;

        token1 = _token1;
    }

    function getReserves() external pure returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return (0, 0, 0);
    }

    function mint(address) external returns (uint256 liquidity) {
        attacked = true;

        return 1000;
    }
}
