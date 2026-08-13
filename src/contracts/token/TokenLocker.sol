// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

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

    uint256 public nextLockId;
    mapping(uint256 => Lock) public locks;

    event Locked(
        uint256 indexed lockId,
        address indexed token,
        address indexed owner,
        uint256 amount,
        uint256 unlockTime
    );

    event Unlocked(
        uint256 indexed lockId,
        address indexed owner,
        uint256 amount
    );

    /// @notice Locks tokens until a specific unlock time
    function lockTokens(
        address token,
        uint256 amount,
        uint256 unlockTime
    ) external nonReentrant returns (uint256 lockId) {
        require(token != address(0), "TokenLocker: zero token address");
        require(amount > 0, "TokenLocker: amount must be > 0");
        
        // Այստեղ կիրառում ենք ապագա ժամանակի ստուգում՝ բավարար ճկունությամբ
        require(unlockTime > block.timestamp, "TokenLocker: unlock time must be in future");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        lockId = nextLockId++;
        
        locks[lockId] = Lock({
            token: token,
            owner: msg.sender,
            amount: amount,
            unlockTime: unlockTime,
            claimed: false
        });

        emit Locked(lockId, token, msg.sender, amount, unlockTime);
    }

    /// @notice Unlocks tokens after the unlock time has passed
    function unlock(uint256 lockId) external nonReentrant {
        Lock storage l = locks[lockId];

        require(l.owner != address(0), "TokenLocker: lock does not exist");
        require(msg.sender == l.owner, "TokenLocker: not the owner");
        require(!l.claimed, "TokenLocker: already claimed");
        require(block.timestamp >= l.unlockTime, "TokenLocker: tokens still locked");

        l.claimed = true;
        IERC20(l.token).safeTransfer(l.owner, l.amount);

        emit Unlocked(lockId, l.owner, l.amount);
    }

    /// @notice Returns the details of a specific lock
    function getLock(uint256 lockId)
        external
        view
        returns (
            address token,
            address owner,
            uint256 amount,
            uint256 unlockTime,
            bool claimed
        )
    {
        Lock memory l = locks[lockId];
        return (l.token, l.owner, l.amount, l.unlockTime, l.claimed);
    }
}