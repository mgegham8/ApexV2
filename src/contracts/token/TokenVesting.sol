// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenVesting is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error ZeroToken();
    error ZeroBeneficiary();
    error ZeroAmount();
    error ZeroDuration();
    error InvalidCliff();
    error TimestampOverflow();
    error NotBeneficiary();
    error NothingToRelease();

    IERC20 public immutable token;

    address public immutable beneficiary;

    uint256 public immutable start;
    uint256 public immutable cliff;
    uint256 public immutable duration;
    uint256 public immutable end;

    uint256 public immutable totalAmount;

    uint256 public released;

    event TokensReleased(
        address indexed beneficiary,
        uint256 amount
    );

    constructor(
        address _token,
        address _beneficiary,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration,
        uint256 _amount
    ) {
        if (_token == address(0)) {
            revert ZeroToken();
        }

        if (_beneficiary == address(0)) {
            revert ZeroBeneficiary();
        }

        if (_amount == 0) {
            revert ZeroAmount();
        }

        if (_duration == 0) {
            revert ZeroDuration();
        }

        if (_cliffDuration > _duration) {
            revert InvalidCliff();
        }

        if (
            _start >
            type(uint256).max - _duration
        ) {
            revert TimestampOverflow();
        }

        token =
            IERC20(_token);

        beneficiary =
            _beneficiary;

        start =
            _start;

        cliff =
            _start +
            _cliffDuration;

        duration =
            _duration;

        end =
            _start +
            _duration;

        totalAmount =
            _amount;
    }

    function release()
        external
        nonReentrant
    {
        if (
            msg.sender !=
            beneficiary
        ) {
            revert NotBeneficiary();
        }

        uint256 amount =
            releasableAmount();

        if (amount == 0) {
            revert NothingToRelease();
        }

        released +=
            amount;

        token.safeTransfer(
            beneficiary,
            amount
        );

        emit TokensReleased(
            beneficiary,
            amount
        );
    }

    function releasableAmount()
        public
        view
        returns (uint256)
    {
        return
            vestedAmount(
                block.timestamp
            ) -
            released;
    }

    function vestedAmount(
        uint256 timestamp
    )
        public
        view
        returns (uint256)
    {
        if (
            timestamp <
            cliff
        ) {
            return 0;
        }

        if (
            timestamp >=
            end
        ) {
            return totalAmount;
        }

        return
            totalAmount *
            (
                timestamp -
                start
            ) /
            duration;
    }
}