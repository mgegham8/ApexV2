// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IApexFlashPair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IApexFlashToken {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract FlashLoanAttacker {
    error InvalidCaller();
    error TransferFailed();

    address public immutable pair;
    address public immutable owner;

    constructor(address _pair) {
        pair = _pair;

        owner = msg.sender;
    }

    function attackToken0(uint256 amount) external {
        IApexFlashPair(pair).swap(amount, 0, address(this), abi.encode(uint8(0)));
    }

    function attackToken1(uint256 amount) external {
        IApexFlashPair(pair).swap(0, amount, address(this), abi.encode(uint8(1)));
    }

    function apexV2Call(address, uint256 amount0, uint256 amount1, bytes calldata) external {
        if (msg.sender != pair) {
            revert InvalidCaller();
        }

        /*
         * Intentional malicious behavior:
         * send borrowed assets to owner and do not repay pair.
         *
         * The surrounding pair.swap() transaction must revert.
         */

        if (amount0 != 0) {
            address token0 = IApexFlashPair(pair).token0();

            bool success = IApexFlashToken(token0).transfer(owner, amount0);

            if (!success) {
                revert TransferFailed();
            }
        }

        if (amount1 != 0) {
            address token1 = IApexFlashPair(pair).token1();

            bool success = IApexFlashToken(token1).transfer(owner, amount1);

            if (!success) {
                revert TransferFailed();
            }
        }
    }
}
