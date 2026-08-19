// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/launch/ApexVesting.sol";
import "../src/contracts/test/MockERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract ApexVestingFinalSecurityTest is Test {
    ApexVesting internal vesting;
    MockERC20 internal token;

    address internal user;
    address internal user2;
    address internal operator;
    address internal attacker;

    uint256 internal constant TOTAL_ALLOCATION = 1_000 ether;
    uint256 internal constant DURATION = 365 days;
    uint256 internal constant CLIFF = 30 days;

    function setUp() public {
        user = makeAddr("user");
        user2 = makeAddr("user2");
        operator = makeAddr("operator");
        attacker = makeAddr("attacker");

        token = new MockERC20(
            "Apex Token",
            "APEX"
        );

        vesting = new ApexVesting(
            address(token)
        );

        vesting.setOperator(
            operator,
            true
        );

        token.mint(
            address(vesting),
            10_000_000 ether
        );
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function test_constructor_setsToken() public view {
        assertEq(
            address(vesting.token()),
            address(token)
        );

        assertEq(
            vesting.owner(),
            address(this)
        );
    }

    function test_constructor_revertsZeroToken() public {
        vm.expectRevert(
            ApexVesting.ZeroToken.selector
        );

        new ApexVesting(
            address(0)
        );
    }

    // ============================================================
    // OPERATOR MANAGEMENT
    // ============================================================

    function test_ownerCanSetOperator() public {
        address newOperator =
            makeAddr("newOperator");

        vesting.setOperator(
            newOperator,
            true
        );

        assertTrue(
            vesting.operators(newOperator)
        );
    }

    function test_ownerCanRemoveOperator() public {
        assertTrue(
            vesting.operators(operator)
        );

        vesting.setOperator(
            operator,
            false
        );

        assertFalse(
            vesting.operators(operator)
        );
    }

    function test_setOperator_emitsEvent() public {
        address newOperator =
            makeAddr("newOperator");

        vm.expectEmit(
            true,
            false,
            false,
            true
        );

        emit ApexVesting.OperatorUpdated(
            newOperator,
            true
        );

        vesting.setOperator(
            newOperator,
            true
        );
    }

    function test_setOperator_revertsZeroOperator() public {
        vm.expectRevert(
            ApexVesting.ZeroOperator.selector
        );

        vesting.setOperator(
            address(0),
            true
        );
    }

    function test_nonOwnerCannotSetOperator() public {
        vm.prank(attacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                attacker
            )
        );

        vesting.setOperator(
            makeAddr("newOperator"),
            true
        );
    }

    function test_removedOperatorCannotCreateVesting() public {
        vesting.setOperator(
            operator,
            false
        );

        vm.prank(operator);

        vm.expectRevert(
            ApexVesting.NotOperator.selector
        );

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            block.timestamp,
            CLIFF,
            DURATION
        );
    }

    // ============================================================
    // CREATE VESTING
    // ============================================================

    function test_ownerCanCreateVesting() public {
        uint256 start =
            block.timestamp;

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(user);

        assertEq(
            schedule.totalAmount,
            TOTAL_ALLOCATION
        );

        assertEq(
            schedule.claimed,
            0
        );

        assertEq(
            schedule.startTime,
            start
        );

        assertEq(
            schedule.cliff,
            CLIFF
        );

        assertEq(
            schedule.duration,
            DURATION
        );
    }

    function test_operatorCanCreateVesting() public {
        uint256 start =
            block.timestamp;

        vm.prank(operator);

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(user);

        assertEq(
            schedule.totalAmount,
            TOTAL_ALLOCATION
        );
    }

    function test_createVesting_emitsEvent() public {
        uint256 start =
            block.timestamp;

        vm.expectEmit(
            true,
            false,
            false,
            true
        );

        emit ApexVesting.VestingCreated(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );

        vm.prank(operator);

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_updatesTotalUnclaimed() public {
        _createDefaultVesting(
            user,
            TOTAL_ALLOCATION
        );

        assertEq(
            vesting.totalUnclaimed(),
            TOTAL_ALLOCATION
        );
    }

    function test_createVesting_multipleUsersTracksTotalUnclaimed()
        public
    {
        uint256 amount1 =
            1_000 ether;

        uint256 amount2 =
            2_000 ether;

        _createDefaultVesting(
            user,
            amount1
        );

        _createDefaultVesting(
            user2,
            amount2
        );

        assertEq(
            vesting.totalUnclaimed(),
            amount1 + amount2
        );
    }

    function test_createVesting_revertsUnauthorized() public {
        vm.prank(attacker);

        vm.expectRevert(
            ApexVesting.NotOperator.selector
        );

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            block.timestamp,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_revertsZeroUser() public {
        vm.expectRevert(
            ApexVesting.ZeroUser.selector
        );

        vesting.createVesting(
            address(0),
            TOTAL_ALLOCATION,
            block.timestamp,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_revertsZeroAmount() public {
        vm.expectRevert(
            ApexVesting.ZeroAmount.selector
        );

        vesting.createVesting(
            user,
            0,
            block.timestamp,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_revertsZeroDuration() public {
        vm.expectRevert(
            ApexVesting.ZeroDuration.selector
        );

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            block.timestamp,
            0,
            0
        );
    }

    function test_createVesting_revertsCliffGreaterThanDuration()
        public
    {
        vm.expectRevert(
            ApexVesting.InvalidCliff.selector
        );

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            block.timestamp,
            DURATION + 1,
            DURATION
        );
    }

    function test_createVesting_allowsCliffEqualDuration() public {
        uint256 start =
            block.timestamp;

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            DURATION,
            DURATION
        );

        vm.warp(
            start + DURATION
        );

        assertEq(
            vesting.claimable(user),
            TOTAL_ALLOCATION
        );
    }

    function test_createVesting_revertsTimestampOverflow() public {
        vm.expectRevert(
            ApexVesting.InvalidStartTime.selector
        );

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            type(uint256).max,
            0,
            1
        );
    }

    function test_createVesting_revertsDuplicateSchedule() public {
        _createDefaultVesting(
            user,
            TOTAL_ALLOCATION
        );

        vm.expectRevert(
            ApexVesting.VestingAlreadyExists.selector
        );

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            block.timestamp,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_revertsInsufficientFunding() public {
        MockERC20 smallToken =
            new MockERC20(
                "Small",
                "SMALL"
            );

        ApexVesting smallVesting =
            new ApexVesting(
                address(smallToken)
            );

        smallToken.mint(
            address(smallVesting),
            100 ether
        );

        vm.expectRevert(
            ApexVesting.InsufficientFunding.selector
        );

        smallVesting.createVesting(
            user,
            101 ether,
            block.timestamp,
            0,
            DURATION
        );
    }

    function test_createVesting_cumulativeFundingProtection()
        public
    {
        MockERC20 smallToken =
            new MockERC20(
                "Small",
                "SMALL"
            );

        ApexVesting smallVesting =
            new ApexVesting(
                address(smallToken)
            );

        smallToken.mint(
            address(smallVesting),
            1_000 ether
        );

        smallVesting.createVesting(
            user,
            600 ether,
            block.timestamp,
            0,
            DURATION
        );

        vm.expectRevert(
            ApexVesting.InsufficientFunding.selector
        );

        smallVesting.createVesting(
            user2,
            401 ether,
            block.timestamp,
            0,
            DURATION
        );

        assertEq(
            smallVesting.totalUnclaimed(),
            600 ether
        );
    }

    // ============================================================
    // CLAIMABLE
    // ============================================================

    function test_claimable_noScheduleReturnsZero()
        public
        view
    {
        assertEq(
            vesting.claimable(user),
            0
        );
    }

    function test_vestedAmount_noScheduleReturnsZero()
        public
        view
    {
        assertEq(
            vesting.vestedAmount(user),
            0
        );
    }

    function test_beforeStart_claimableIsZero() public {
        uint256 start =
            block.timestamp + 100 days;

        vm.prank(operator);

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );

        assertEq(
            vesting.claimable(user),
            0
        );
    }

    function testCliffPeriodNoClaim() public {
        uint256 startTimestamp =
            block.timestamp;

        vm.prank(operator);

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            startTimestamp,
            CLIFF,
            DURATION
        );

        vm.warp(
            startTimestamp + 15 days
        );

        assertEq(
            vesting.claimable(user),
            0
        );

        vm.prank(user);

        vm.expectRevert(
            ApexVesting.NothingToClaim.selector
        );

        vesting.claim();
    }

    function test_exactlyBeforeCliff_claimableZero() public {
        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );

        vm.warp(
            start + CLIFF - 1
        );

        assertEq(
            vesting.claimable(user),
            0
        );
    }

    function test_exactCliffBoundary_unlocksLinearAmount()
        public
    {
        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );

        vm.warp(
            start + CLIFF
        );

        uint256 expected =
            (
                TOTAL_ALLOCATION *
                CLIFF
            ) /
            DURATION;

        assertEq(
            vesting.claimable(user),
            expected
        );

        assertEq(
            vesting.vestedAmount(user),
            expected
        );
    }

    function testClaimAfterCliff() public {
        uint256 startTimestamp =
            block.timestamp;

        vm.prank(operator);

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            startTimestamp,
            CLIFF,
            DURATION
        );

        vm.warp(
            startTimestamp + 60 days
        );

        uint256 claimableBefore =
            vesting.claimable(user);

        uint256 expected =
            (
                TOTAL_ALLOCATION *
                60 days
            ) /
            DURATION;

        assertEq(
            claimableBefore,
            expected
        );

        vm.prank(user);
        vesting.claim();

        assertEq(
            token.balanceOf(user),
            expected
        );

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(user);

        assertEq(
            schedule.claimed,
            expected
        );

        assertEq(
            vesting.totalUnclaimed(),
            TOTAL_ALLOCATION - expected
        );
    }

    function test_halfDurationVestsHalf() public {
        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            0,
            DURATION
        );

        vm.warp(
            start + DURATION / 2
        );

        assertEq(
            vesting.vestedAmount(user),
            TOTAL_ALLOCATION / 2
        );

        assertEq(
            vesting.claimable(user),
            TOTAL_ALLOCATION / 2
        );
    }

    function testFullVestingComplete() public {
        uint256 startTimestamp =
            block.timestamp;

        vm.prank(operator);

        vesting.createVesting(
            user,
            TOTAL_ALLOCATION,
            startTimestamp,
            CLIFF,
            DURATION
        );

        vm.warp(
            startTimestamp + DURATION
        );

        assertEq(
            vesting.claimable(user),
            TOTAL_ALLOCATION
        );

        vm.prank(user);
        vesting.claim();

        assertEq(
            token.balanceOf(user),
            TOTAL_ALLOCATION
        );

        assertEq(
            vesting.totalUnclaimed(),
            0
        );

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(user);

        assertEq(
            schedule.claimed,
            TOTAL_ALLOCATION
        );
    }

    function test_afterDuration_claimableCappedAtTotal()
        public
    {
        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            0,
            DURATION
        );

        vm.warp(
            start +
            DURATION +
            10_000 days
        );

        assertEq(
            vesting.claimable(user),
            TOTAL_ALLOCATION
        );

        assertEq(
            vesting.vestedAmount(user),
            TOTAL_ALLOCATION
        );
    }

    // ============================================================
    // CLAIM
    // ============================================================

    function test_claim_revertsWithoutVesting() public {
        vm.prank(user);

        vm.expectRevert(
            ApexVesting.NoVesting.selector
        );

        vesting.claim();
    }

    function test_claim_revertsNothingAvailable() public {
        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );

        vm.prank(user);

        vm.expectRevert(
            ApexVesting.NothingToClaim.selector
        );

        vesting.claim();
    }

    function test_claim_emitsEvent() public {
        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            0,
            DURATION
        );

        vm.warp(
            start + DURATION / 2
        );

        uint256 expected =
            TOTAL_ALLOCATION / 2;

        vm.expectEmit(
            true,
            false,
            false,
            true
        );

        emit ApexVesting.Claimed(
            user,
            expected
        );

        vm.prank(user);
        vesting.claim();
    }

    function test_multiplePartialClaims() public {
        uint256 start =
            vm.getBlockTimestamp();

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            0,
            DURATION
        );

        // ============================================================
        // FIRST CLAIM — DAY 90
        // ============================================================

        vm.warp(
            start + 90 days
        );

        uint256 firstTimestamp =
            vm.getBlockTimestamp();

        assertEq(
            firstTimestamp,
            start + 90 days
        );

        uint256 vestedAtFirst =
            (
                TOTAL_ALLOCATION *
                (
                    firstTimestamp -
                    start
                )
            ) /
            DURATION;

        assertEq(
            vesting.claimable(user),
            vestedAtFirst
        );

        vm.prank(user);
        vesting.claim();

        assertEq(
            token.balanceOf(user),
            vestedAtFirst
        );

        ApexVesting.Schedule memory scheduleAfterFirst =
            vesting.getSchedule(user);

        assertEq(
            scheduleAfterFirst.claimed,
            vestedAtFirst
        );

        assertEq(
            vesting.claimable(user),
            0
        );

        // ============================================================
        // SECOND CLAIM — DAY 180
        // ============================================================

        vm.warp(
            start + 180 days
        );

        uint256 secondTimestamp =
            vm.getBlockTimestamp();

        assertEq(
            secondTimestamp,
            start + 180 days
        );

        uint256 vestedAtSecond =
            (
                TOTAL_ALLOCATION *
                (
                    secondTimestamp -
                    start
                )
            ) /
            DURATION;

        uint256 secondClaimable =
            vestedAtSecond -
            vestedAtFirst;

        assertEq(
            vesting.claimable(user),
            secondClaimable
        );

        uint256 balanceBeforeSecondClaim =
            token.balanceOf(user);

        vm.prank(user);
        vesting.claim();

        assertEq(
            token.balanceOf(user),
            balanceBeforeSecondClaim +
            secondClaimable
        );

        assertEq(
            token.balanceOf(user),
            vestedAtSecond
        );

        ApexVesting.Schedule memory scheduleAfterSecond =
            vesting.getSchedule(user);

        assertEq(
            scheduleAfterSecond.claimed,
            vestedAtSecond
        );

        assertEq(
            vesting.claimable(user),
            0
        );

        assertEq(
            vesting.totalUnclaimed(),
            TOTAL_ALLOCATION -
            vestedAtSecond
        );
    }

    function test_claimFullThenSecondClaimReverts() public {
        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            0,
            DURATION
        );

        vm.warp(
            start + DURATION
        );

        vm.prank(user);
        vesting.claim();

        vm.prank(user);

        vm.expectRevert(
            ApexVesting.NothingToClaim.selector
        );

        vesting.claim();
    }

    function test_claimDoesNotAffectOtherUser() public {
        uint256 amount1 =
            1_000 ether;

        uint256 amount2 =
            2_000 ether;

        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            amount1,
            start,
            0,
            DURATION
        );

        _createVesting(
            user2,
            amount2,
            start,
            0,
            DURATION
        );

        vm.warp(
            start + DURATION
        );

        vm.prank(user);
        vesting.claim();

        assertEq(
            token.balanceOf(user),
            amount1
        );

        assertEq(
            token.balanceOf(user2),
            0
        );

        assertEq(
            vesting.claimable(user2),
            amount2
        );

        assertEq(
            vesting.totalUnclaimed(),
            amount2
        );
    }

    function test_claimExactEndTimestamp() public {
        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            TOTAL_ALLOCATION,
            start,
            CLIFF,
            DURATION
        );

        vm.warp(
            start + DURATION
        );

        vm.prank(user);
        vesting.claim();

        assertEq(
            token.balanceOf(user),
            TOTAL_ALLOCATION
        );

        assertEq(
            vesting.claimable(user),
            0
        );
    }

    // ============================================================
    // FUZZ
    // ============================================================

    function testFuzz_claimableLinearVesting(
        uint96 rawAmount,
        uint32 rawDuration,
        uint32 rawElapsed
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1,
                1_000_000 ether
            );

        uint256 fuzzDuration =
            bound(
                uint256(rawDuration),
                1 days,
                10 * 365 days
            );

        uint256 elapsed =
            bound(
                uint256(rawElapsed),
                0,
                fuzzDuration
            );

        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            amount,
            start,
            0,
            fuzzDuration
        );

        vm.warp(
            start + elapsed
        );

        uint256 expected;

        if (
            elapsed >= fuzzDuration
        ) {
            expected =
                amount;
        } else {
            expected =
                (
                    amount *
                    elapsed
                ) /
                fuzzDuration;
        }

        assertEq(
            vesting.claimable(user),
            expected
        );

        assertEq(
            vesting.vestedAmount(user),
            expected
        );
    }

    function testFuzz_cliffBlocksClaimBeforeBoundary(
        uint96 rawAmount,
        uint32 rawDuration,
        uint32 rawCliff
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1,
                1_000_000 ether
            );

        uint256 fuzzDuration =
            bound(
                uint256(rawDuration),
                2 days,
                10 * 365 days
            );

        uint256 fuzzCliff =
            bound(
                uint256(rawCliff),
                1,
                fuzzDuration
            );

        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            amount,
            start,
            fuzzCliff,
            fuzzDuration
        );

        vm.warp(
            start +
            fuzzCliff -
            1
        );

        assertEq(
            vesting.claimable(user),
            0
        );
    }

    function testFuzz_fullVestingAlwaysCapsAtTotal(
        uint96 rawAmount,
        uint32 rawDuration
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1,
                1_000_000 ether
            );

        uint256 fuzzDuration =
            bound(
                uint256(rawDuration),
                1,
                10 * 365 days
            );

        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            amount,
            start,
            0,
            fuzzDuration
        );

        vm.warp(
            start + fuzzDuration
        );

        assertEq(
            vesting.claimable(user),
            amount
        );

        assertEq(
            vesting.vestedAmount(user),
            amount
        );
    }

    function testFuzz_partialClaimAccounting(
        uint96 rawAmount,
        uint32 rawDuration,
        uint32 rawElapsed
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1 ether,
                1_000_000 ether
            );

        uint256 fuzzDuration =
            bound(
                uint256(rawDuration),
                2 days,
                10 * 365 days
            );

        uint256 elapsed =
            bound(
                uint256(rawElapsed),
                1,
                fuzzDuration
            );

        uint256 start =
            block.timestamp;

        _createVesting(
            user,
            amount,
            start,
            0,
            fuzzDuration
        );

        vm.warp(
            start + elapsed
        );

        uint256 expected;

        if (
            elapsed ==
            fuzzDuration
        ) {
            expected =
                amount;
        } else {
            expected =
                (
                    amount *
                    elapsed
                ) /
                fuzzDuration;
        }

        if (
            expected == 0
        ) {
            return;
        }

        vm.prank(user);
        vesting.claim();

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(user);

        assertEq(
            schedule.claimed,
            expected
        );

        assertEq(
            token.balanceOf(user),
            expected
        );

        assertEq(
            vesting.totalUnclaimed(),
            amount - expected
        );

        assertEq(
            vesting.claimable(user),
            0
        );
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _createDefaultVesting(
        address beneficiary,
        uint256 amount
    )
        internal
    {
        _createVesting(
            beneficiary,
            amount,
            block.timestamp,
            CLIFF,
            DURATION
        );
    }

    function _createVesting(
        address beneficiary,
        uint256 amount,
        uint256 start,
        uint256 vestingCliff,
        uint256 vestingDuration
    )
        internal
    {
        vm.prank(operator);

        vesting.createVesting(
            beneficiary,
            amount,
            start,
            vestingCliff,
            vestingDuration
        );
    }
}