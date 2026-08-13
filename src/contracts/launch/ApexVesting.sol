// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApexVesting is Ownable {

    IERC20 public immutable token;

    mapping(address => bool) public operators;

    struct Schedule {
        uint256 totalAmount;
        uint256 claimed;
        uint256 startTime;
        uint256 cliff;
        uint256 duration;
    }

    mapping(address => Schedule) public schedules;

    event OperatorUpdated(address indexed operator, bool status);
    event VestingCreated(address indexed user, uint256 amount, uint256 startTime, uint256 cliff, uint256 duration);
    event Claimed(address indexed user, uint256 amount);

    modifier onlyOperator() {
        require(msg.sender == owner() || operators[msg.sender], "not operator");
        _;
    }

    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "zero token");
        token = IERC20(_token);
    }

    function setOperator(address operator, bool status) external onlyOwner {
        require(operator != address(0), "zero operator");
        operators[operator] = status;
        emit OperatorUpdated(operator, status);
    }

    function createVesting(
        address user,
        uint256 amount,
        uint256 startTime,
        uint256 cliff,
        uint256 duration
    ) external onlyOperator {
        require(user != address(0), "zero user");
        require(amount > 0, "zero amount");
        require(duration > 0, "zero duration");
        require(schedules[user].totalAmount == 0, "exists");

        schedules[user] = Schedule({
            totalAmount: amount,
            claimed: 0,
            startTime: startTime,
            cliff: cliff,
            duration: duration
        });

        emit VestingCreated(user, amount, startTime, cliff, duration);
    }

    function claim() external {
        Schedule storage s = schedules[msg.sender];

        require(s.totalAmount > 0, "no vesting");

        uint256 amount = claimable(msg.sender);

        require(amount > 0, "nothing");

        s.claimed += amount;

        require(token.transfer(msg.sender, amount), "transfer failed");

        emit Claimed(msg.sender, amount);
    }

    function claimable(address user) public view returns(uint256) {
        Schedule memory s = schedules[user];

        if (block.timestamp < s.startTime + s.cliff) {
            return 0;
        }

        uint256 unlocked;

        if (block.timestamp >= s.startTime + s.duration) {
            unlocked = s.totalAmount;
        } else {
            uint256 passed = block.timestamp - s.startTime;
            unlocked = s.totalAmount * passed / s.duration;
        }

        return unlocked - s.claimed;
    }

    function getSchedule(address user) external view returns(Schedule memory) {
        return schedules[user];
    }
}