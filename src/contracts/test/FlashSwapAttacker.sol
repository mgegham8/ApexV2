// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IApexV2Callee {
    function apexV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    )
        external;
}

interface IApexV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    )
        external;
}

contract FlashSwapAttacker is IApexV2Callee {
    bool public attack;

    function execute(
        address pair,
        uint256 amount0,
        uint256 amount1
    )
        external
    {
        IApexV2Pair(pair).swap(
            amount0,
            amount1,
            address(this),
            abi.encode("attack")
        );
    }

    function apexV2Call(
        address,
        uint256,
        uint256,
        bytes calldata
    )
        external
        view
        override
    {
        if (attack) {
            return;
        }

        // intentionally do not repay
    }

    function setAttack(
        bool value
    )
        external
    {
        attack =
            value;
    }
}