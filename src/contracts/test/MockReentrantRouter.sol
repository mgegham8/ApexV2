// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IApexReentrantController {
    function launch(address weth, uint256 tokenAmount, uint256 ethAmount) external payable;
}

contract MockReentrantRouter {
    error ControllerAlreadySet();
    error ZeroController();
    error InsufficientETH();

    address public controller;

    address public weth;

    uint256 public tokenAmount;
    uint256 public ethAmount;

    bool public attack;

    // ============================================================
    // SETUP
    // ============================================================

    function setController(address _controller) external {
        if (_controller == address(0)) {
            revert ZeroController();
        }

        if (controller != address(0)) {
            revert ControllerAlreadySet();
        }

        controller = _controller;
    }

    function setAttack(address _weth, uint256 _tokenAmount, uint256 _ethAmount) external {
        weth = _weth;

        tokenAmount = _tokenAmount;

        ethAmount = _ethAmount;

        attack = true;
    }

    // ============================================================
    // MOCK ROUTER
    // ============================================================

    function addLiquidityETH(address, uint256 amountTokenDesired, uint256, uint256, address, uint256)
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        if (attack) {
            attack = false;

            if (address(this).balance < ethAmount) {
                revert InsufficientETH();
            }

            /*
             * Intentional reentrancy attempt.
             *
             * The real ApexLaunchController must reject this call.
             */
            IApexReentrantController(controller).launch{value: ethAmount}(weth, tokenAmount, ethAmount);
        }

        return (amountTokenDesired, msg.value, 1);
    }

    receive() external payable {}
}
