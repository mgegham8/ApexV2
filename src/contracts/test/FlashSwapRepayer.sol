// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IApexV2Callee {
    function ApexV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

interface IApexV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function transfer(
        address to,
        uint amount
    ) external returns(bool);
}

interface IERC20Info {
    function token0() external view returns(address);
    function token1() external view returns(address);
}

contract FlashSwapRepayer is IApexV2Callee {

    function execute(
        address pair,
        uint amount0,
        uint amount1
    ) external {
        IApexV2Pair(pair).swap(
            amount0,
            amount1,
            address(this),
            abi.encode(pair)
        );
    }

    function ApexV2Call(
        address,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        address pair = abi.decode(data, (address));
        address token0 = IERC20Info(pair).token0();
        address token1 = IERC20Info(pair).token1();

        // Ճիշտ բանաձև՝ գումարը + 0.3% վճար
        uint repay0 = amount0 == 0 ? 0 : (amount0 * 1000) / 997 + 1;
        uint repay1 = amount1 == 0 ? 0 : (amount1 * 1000) / 997 + 1;

        if(amount0 > 0) {
            IERC20(token0).transfer(pair, repay0);
        }

        if(amount1 > 0) {
            IERC20(token1).transfer(pair, repay1);
        }
    }
}