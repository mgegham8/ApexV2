// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenLocker is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Lock {
        address token;
        address owner;
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    error ZeroToken();
    error ZeroAmount();
    error InvalidUnlockTime();
    error LockNotFound();
    error NotLockOwner();
    error AlreadyClaimed();
    error StillLocked();
    error ZeroReceived();

    uint256 public nextLockId = 1;

    mapping(uint256 => Lock) public locks;

    event Locked(
        uint256 indexed lockId, address indexed token, address indexed owner, uint256 amount, uint256 unlockTime
    );

    event Unlocked(uint256 indexed lockId, address indexed owner, uint256 amount);

    function lockTokens(address token, uint256 amount, uint256 unlockTime)
        external
        nonReentrant
        returns (uint256 lockId)
    {
        if (token == address(0)) {
            revert ZeroToken();
        }

        if (amount == 0) {
            revert ZeroAmount();
        }

        if (unlockTime <= block.timestamp) {
            revert InvalidUnlockTime();
        }

        IERC20 tokenContract = IERC20(token);

        uint256 balanceBefore = tokenContract.balanceOf(address(this));

        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        uint256 balanceAfter = tokenContract.balanceOf(address(this));

        uint256 received = balanceAfter - balanceBefore;

        if (received == 0) {
            revert ZeroReceived();
        }

        lockId = nextLockId++;

        locks[lockId] =
            Lock({token: token, owner: msg.sender, amount: received, unlockTime: unlockTime, claimed: false});

        emit Locked(lockId, token, msg.sender, received, unlockTime);
    }

    function unlock(uint256 lockId) external nonReentrant {
        Lock storage lockData = locks[lockId];

        if (lockData.owner == address(0)) {
            revert LockNotFound();
        }

        if (msg.sender != lockData.owner) {
            revert NotLockOwner();
        }

        if (lockData.claimed) {
            revert AlreadyClaimed();
        }

        if (block.timestamp < lockData.unlockTime) {
            revert StillLocked();
        }

        uint256 amount = lockData.amount;

        lockData.claimed = true;

        IERC20(lockData.token).safeTransfer(lockData.owner, amount);

        emit Unlocked(lockId, lockData.owner, amount);
    }

    function getLock(uint256 lockId)
        external
        view
        returns (address token, address owner, uint256 amount, uint256 unlockTime, bool claimed)
    {
        Lock memory lockData = locks[lockId];

        return (lockData.token, lockData.owner, lockData.amount, lockData.unlockTime, lockData.claimed);
    }
}
