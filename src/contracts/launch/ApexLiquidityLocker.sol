// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ApexLiquidityLocker {
    using SafeERC20 for IERC20;

    // ============================================================
    // ERRORS
    // ============================================================

    error NotOwner();
    error ZeroLPToken();
    error TokenHasNoCode();
    error ZeroAmount();
    error InvalidUnlockTime();
    error AlreadyLocked();
    error NotLocked();
    error NotUnlocked();

    // ============================================================
    // STORAGE
    // ============================================================

    address public immutable owner;

    IERC20 public immutable lpToken;

    uint256 public unlockTime;

    uint256 public lockedAmount;

    bool public locked;

    // ============================================================
    // EVENTS
    // ============================================================

    event LiquidityLocked(
        uint256 amount,
        uint256 unlockTime
    );

    event LiquidityWithdrawn(
        uint256 amount
    );

    // ============================================================
    // MODIFIERS
    // ============================================================

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        _;
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor(
        address _lpToken
    ) {
        if (_lpToken == address(0)) {
            revert ZeroLPToken();
        }

        if (_lpToken.code.length == 0) {
            revert TokenHasNoCode();
        }

        owner =
            msg.sender;

        lpToken =
            IERC20(_lpToken);
    }

    // ============================================================
    // LOCK
    // ============================================================

    function lock(
        uint256 amount,
        uint256 _unlockTime
    )
        external
        onlyOwner
    {
        if (locked) {
            revert AlreadyLocked();
        }

        if (amount == 0) {
            revert ZeroAmount();
        }

        if (
            _unlockTime <=
            block.timestamp
        ) {
            revert InvalidUnlockTime();
        }

        /*
         * Pull tokens before committing lock state.
         *
         * SafeERC20 supports:
         * - standard ERC20 returning true
         * - no-return ERC20
         *
         * and reverts on failed / false transfers.
         */
        lpToken.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        lockedAmount =
            amount;

        unlockTime =
            _unlockTime;

        locked =
            true;

        emit LiquidityLocked(
            amount,
            _unlockTime
        );
    }

    // ============================================================
    // WITHDRAW
    // ============================================================

    function withdraw()
        external
        onlyOwner
    {
        if (!locked) {
            revert NotLocked();
        }

        if (
            block.timestamp <
            unlockTime
        ) {
            revert NotUnlocked();
        }

        uint256 amount =
            lockedAmount;

        /*
         * Effects before interaction.
         */
        lockedAmount =
            0;

        unlockTime =
            0;

        locked =
            false;

        lpToken.safeTransfer(
            owner,
            amount
        );

        emit LiquidityWithdrawn(
            amount
        );
    }

    // ============================================================
    // VIEWS
    // ============================================================

    function getLockedAmount()
        external
        view
        returns (uint256)
    {
        return lockedAmount;
    }

    function isUnlocked()
        external
        view
        returns (bool)
    {
        return
            locked &&
            block.timestamp >=
            unlockTime;
    }
}