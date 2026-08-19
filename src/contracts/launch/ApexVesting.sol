// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApexVesting is Ownable {
    using SafeERC20 for IERC20;

    // ============================================================
    // ERRORS
    // ============================================================

    error ZeroToken();
    error ZeroOperator();
    error ZeroUser();
    error ZeroAmount();
    error ZeroDuration();
    error InvalidCliff();
    error InvalidStartTime();
    error NotOperator();
    error VestingAlreadyExists();
    error NoVesting();
    error NothingToClaim();
    error InsufficientFunding();

    // ============================================================
    // STORAGE
    // ============================================================

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

    uint256 public totalUnclaimed;

    // ============================================================
    // EVENTS
    // ============================================================

    event OperatorUpdated(
        address indexed operator,
        bool status
    );

    event VestingCreated(
        address indexed user,
        uint256 amount,
        uint256 startTime,
        uint256 cliff,
        uint256 duration
    );

    event Claimed(
        address indexed user,
        uint256 amount
    );

    // ============================================================
    // MODIFIERS
    // ============================================================

    modifier onlyOperator() {
        if (
            msg.sender != owner() &&
            !operators[msg.sender]
        ) {
            revert NotOperator();
        }

        _;
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor(
        address _token
    )
        Ownable(msg.sender)
    {
        if (_token == address(0)) {
            revert ZeroToken();
        }

        token =
            IERC20(_token);
    }

    // ============================================================
    // OPERATOR MANAGEMENT
    // ============================================================

    function setOperator(
        address operator,
        bool status
    )
        external
        onlyOwner
    {
        if (operator == address(0)) {
            revert ZeroOperator();
        }

        operators[operator] =
            status;

        emit OperatorUpdated(
            operator,
            status
        );
    }

    // ============================================================
    // CREATE VESTING
    // ============================================================

    function createVesting(
        address user,
        uint256 amount,
        uint256 startTime,
        uint256 cliff,
        uint256 duration
    )
        external
        onlyOperator
    {
        if (user == address(0)) {
            revert ZeroUser();
        }

        if (amount == 0) {
            revert ZeroAmount();
        }

        if (duration == 0) {
            revert ZeroDuration();
        }

        if (cliff > duration) {
            revert InvalidCliff();
        }

        /*
         * duration >= cliff, therefore validating the larger
         * startTime + duration addition protects both timestamps.
         */
        if (
            startTime >
            type(uint256).max - duration
        ) {
            revert InvalidStartTime();
        }

        if (
            schedules[user].totalAmount != 0
        ) {
            revert VestingAlreadyExists();
        }

        uint256 newTotalUnclaimed =
            totalUnclaimed +
            amount;

        if (
            token.balanceOf(address(this)) <
            newTotalUnclaimed
        ) {
            revert InsufficientFunding();
        }

        schedules[user] =
            Schedule({
                totalAmount: amount,
                claimed: 0,
                startTime: startTime,
                cliff: cliff,
                duration: duration
            });

        totalUnclaimed =
            newTotalUnclaimed;

        emit VestingCreated(
            user,
            amount,
            startTime,
            cliff,
            duration
        );
    }

    // ============================================================
    // CLAIM
    // ============================================================

    function claim()
        external
    {
        Schedule storage schedule =
            schedules[msg.sender];

        if (
            schedule.totalAmount == 0
        ) {
            revert NoVesting();
        }

        uint256 vested =
            _vestedAmount(
                schedule
            );

        uint256 previouslyClaimed =
            schedule.claimed;

        if (
            vested <= previouslyClaimed
        ) {
            revert NothingToClaim();
        }

        uint256 amount;

        unchecked {
            amount =
                vested -
                previouslyClaimed;
        }

        /*
         * Effects before interaction.
         *
         * IMPORTANT:
         * claimed stores the cumulative vested amount already paid,
         * not the amount of only the latest claim.
         */
        schedule.claimed =
            vested;

        totalUnclaimed -=
            amount;

        token.safeTransfer(
            msg.sender,
            amount
        );

        emit Claimed(
            msg.sender,
            amount
        );
    }

    // ============================================================
    // CLAIMABLE
    // ============================================================

    function claimable(
        address user
    )
        public
        view
        returns (uint256)
    {
        Schedule storage schedule =
            schedules[user];

        if (
            schedule.totalAmount == 0
        ) {
            return 0;
        }

        uint256 vested =
            _vestedAmount(
                schedule
            );

        uint256 previouslyClaimed =
            schedule.claimed;

        if (
            vested <= previouslyClaimed
        ) {
            return 0;
        }

        unchecked {
            return
                vested -
                previouslyClaimed;
        }
    }

    // ============================================================
    // VESTED AMOUNT
    // ============================================================

    function vestedAmount(
        address user
    )
        external
        view
        returns (uint256)
    {
        Schedule storage schedule =
            schedules[user];

        if (
            schedule.totalAmount == 0
        ) {
            return 0;
        }

        return
            _vestedAmount(
                schedule
            );
    }

    // ============================================================
    // GET SCHEDULE
    // ============================================================

    function getSchedule(
        address user
    )
        external
        view
        returns (Schedule memory)
    {
        return
            schedules[user];
    }

    // ============================================================
    // INTERNAL VESTING CALCULATION
    // ============================================================

    function _vestedAmount(
        Schedule storage schedule
    )
        private
        view
        returns (uint256)
    {
        uint256 timestamp =
            block.timestamp;

        uint256 startTime =
            schedule.startTime;

        uint256 cliffTime =
            startTime +
            schedule.cliff;

        /*
         * Before the cliff absolutely nothing is vested.
         */
        if (
            timestamp <
            cliffTime
        ) {
            return 0;
        }

        uint256 endTime =
            startTime +
            schedule.duration;

        /*
         * At or after the exact end timestamp the complete
         * allocation is vested.
         */
        if (
            timestamp >= endTime
        ) {
            return
                schedule.totalAmount;
        }

        /*
         * Since cliff <= duration and timestamp >= cliffTime,
         * timestamp >= startTime here.
         */
        uint256 elapsed;

        unchecked {
            elapsed =
                timestamp -
                startTime;
        }

        return
            (
                schedule.totalAmount *
                elapsed
            ) /
            schedule.duration;
    }
}