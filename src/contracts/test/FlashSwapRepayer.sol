// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IApexFlashRepayCallee {
    function apexV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    )
        external;
}

interface IApexFlashRepayPair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    )
        external;

    function token0()
        external
        view
        returns (address);

    function token1()
        external
        view
        returns (address);
}

interface IApexFlashRepayToken {
    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool);
}

contract FlashSwapRepayer is IApexFlashRepayCallee {
    error InvalidPair();
    error TransferFailed();

    address public activePair;

    function execute(
        address pair,
        uint256 amount0,
        uint256 amount1
    )
        external
    {
        activePair =
            pair;

        IApexFlashRepayPair(pair).swap(
            amount0,
            amount1,
            address(this),
            abi.encode(pair)
        );

        activePair =
            address(0);
    }

    function apexV2Call(
        address,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    )
        external
        override
    {
        address pair =
            abi.decode(
                data,
                (address)
            );

        if (
            msg.sender != pair ||
            pair != activePair
        ) {
            revert InvalidPair();
        }

        address token0 =
            IApexFlashRepayPair(pair)
                .token0();

        address token1 =
            IApexFlashRepayPair(pair)
                .token1();

        /*
         * Same-token flash repayment:
         *
         * amountIn * 997 >= amountOut * 1000
         *
         * ceil(amountOut * 1000 / 997)
         */
        uint256 repay0 =
            amount0 == 0
                ? 0
                : (
                    amount0 * 1000 +
                    996
                ) / 997;

        uint256 repay1 =
            amount1 == 0
                ? 0
                : (
                    amount1 * 1000 +
                    996
                ) / 997;

        if (repay0 != 0) {
            bool success0 =
                IApexFlashRepayToken(token0)
                    .transfer(
                        pair,
                        repay0
                    );

            if (!success0) {
                revert TransferFailed();
            }
        }

        if (repay1 != 0) {
            bool success1 =
                IApexFlashRepayToken(token1)
                    .transfer(
                        pair,
                        repay1
                    );

            if (!success1) {
                revert TransferFailed();
            }
        }
    }
}