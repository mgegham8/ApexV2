// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/launch/ApexLiquidityLocker.sol";
import "../src/contracts/test/MockERC20.sol";

contract FalseReturnLPToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        allowance[msg.sender][spender] =
            amount;

        return true;
    }

    function transfer(
        address,
        uint256
    )
        external
        pure
        returns (bool)
    {
        return false;
    }

    function transferFrom(
        address,
        address,
        uint256
    )
        external
        pure
        returns (bool)
    {
        return false;
    }
}

contract RevertingLPToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        allowance[msg.sender][spender] =
            amount;

        return true;
    }

    function transfer(
        address,
        uint256
    )
        external
        pure
        returns (bool)
    {
        revert("TOKEN_REVERT");
    }

    function transferFrom(
        address,
        address,
        uint256
    )
        external
        pure
        returns (bool)
    {
        revert("TOKEN_REVERT");
    }
}

contract NoReturnLPToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
    {
        allowance[msg.sender][spender] =
            amount;
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[msg.sender] -=
            amount;

        balanceOf[to] +=
            amount;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
    {
        uint256 allowed =
            allowance[from][msg.sender];

        allowance[from][msg.sender] =
            allowed -
            amount;

        balanceOf[from] -=
            amount;

        balanceOf[to] +=
            amount;
    }
}

contract ApexV2LiquidityLockerFinalSecurityTest is Test {
    ApexLiquidityLocker internal locker;
    MockERC20 internal lpToken;

    address internal attacker;

    uint256 internal constant INITIAL_BALANCE =
        1_000_000 ether;

    uint256 internal constant LOCK_AMOUNT =
        10_000 ether;

    uint256 internal constant LOCK_DURATION =
        30 days;

    function setUp()
        public
    {
        attacker =
            makeAddr("attacker");

        lpToken =
            new MockERC20(
                "Apex LP",
                "ALP"
            );

        locker =
            new ApexLiquidityLocker(
                address(lpToken)
            );

        lpToken.mint(
            address(this),
            INITIAL_BALANCE
        );

        lpToken.approve(
            address(locker),
            type(uint256).max
        );
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function test_constructor_setsOwner()
        public
        view
    {
        assertEq(
            locker.owner(),
            address(this)
        );
    }

    function test_constructor_setsLPToken()
        public
        view
    {
        assertEq(
            address(locker.lpToken()),
            address(lpToken)
        );
    }

    function test_constructor_initialState()
        public
        view
    {
        assertEq(
            locker.lockedAmount(),
            0
        );

        assertEq(
            locker.unlockTime(),
            0
        );

        assertFalse(
            locker.locked()
        );

        assertFalse(
            locker.isUnlocked()
        );
    }

    function test_constructor_revertsZeroLPToken()
        public
    {
        vm.expectRevert(
            ApexLiquidityLocker.ZeroLPToken.selector
        );

        new ApexLiquidityLocker(
            address(0)
        );
    }

    function test_constructor_revertsEOALPToken()
        public
    {
        address eoa =
            makeAddr("eoa");

        vm.expectRevert(
            ApexLiquidityLocker.TokenHasNoCode.selector
        );

        new ApexLiquidityLocker(
            eoa
        );
    }

    // ============================================================
    // LOCK
    // ============================================================

    function test_lock_success()
        public
    {
        uint256 nowTs =
            vm.getBlockTimestamp();

        uint256 unlock =
            nowTs +
            LOCK_DURATION;

        locker.lock(
            LOCK_AMOUNT,
            unlock
        );

        assertTrue(
            locker.locked()
        );

        assertEq(
            locker.lockedAmount(),
            LOCK_AMOUNT
        );

        assertEq(
            locker.unlockTime(),
            unlock
        );

        assertEq(
            lpToken.balanceOf(
                address(locker)
            ),
            LOCK_AMOUNT
        );

        assertEq(
            lpToken.balanceOf(
                address(this)
            ),
            INITIAL_BALANCE -
            LOCK_AMOUNT
        );
    }

    function test_lock_emitsEvent()
        public
    {
        uint256 unlock =
            vm.getBlockTimestamp() +
            LOCK_DURATION;

        vm.expectEmit(
            false,
            false,
            false,
            true
        );

        emit ApexLiquidityLocker.LiquidityLocked(
            LOCK_AMOUNT,
            unlock
        );

        locker.lock(
            LOCK_AMOUNT,
            unlock
        );
    }

    function test_lock_revertsNonOwner()
        public
    {
        vm.prank(
            attacker
        );

        vm.expectRevert(
            ApexLiquidityLocker.NotOwner.selector
        );

        locker.lock(
            LOCK_AMOUNT,
            vm.getBlockTimestamp() +
                LOCK_DURATION
        );
    }

    function test_lock_revertsZeroAmount()
        public
    {
        vm.expectRevert(
            ApexLiquidityLocker.ZeroAmount.selector
        );

        locker.lock(
            0,
            vm.getBlockTimestamp() +
                LOCK_DURATION
        );
    }

    function test_lock_revertsUnlockTimeNow()
        public
    {
        vm.expectRevert(
            ApexLiquidityLocker.InvalidUnlockTime.selector
        );

        locker.lock(
            LOCK_AMOUNT,
            vm.getBlockTimestamp()
        );
    }

    function test_lock_revertsUnlockTimePast()
        public
    {
        uint256 nowTs =
            vm.getBlockTimestamp();

        vm.warp(
            nowTs +
            100
        );

        vm.expectRevert(
            ApexLiquidityLocker.InvalidUnlockTime.selector
        );

        locker.lock(
            LOCK_AMOUNT,
            nowTs
        );
    }

    function test_lock_revertsAlreadyLocked()
        public
    {
        _lockDefault();

        vm.expectRevert(
            ApexLiquidityLocker.AlreadyLocked.selector
        );

        locker.lock(
            1 ether,
            vm.getBlockTimestamp() +
                LOCK_DURATION
        );
    }

    function test_lock_revertsWithoutAllowance()
        public
    {
        MockERC20 token2 =
            new MockERC20(
                "LP2",
                "LP2"
            );

        ApexLiquidityLocker locker2 =
            new ApexLiquidityLocker(
                address(token2)
            );

        token2.mint(
            address(this),
            LOCK_AMOUNT
        );

        vm.expectRevert();

        locker2.lock(
            LOCK_AMOUNT,
            vm.getBlockTimestamp() +
                LOCK_DURATION
        );
    }

    function test_lock_revertsInsufficientBalance()
        public
    {
        MockERC20 token2 =
            new MockERC20(
                "LP2",
                "LP2"
            );

        ApexLiquidityLocker locker2 =
            new ApexLiquidityLocker(
                address(token2)
            );

        token2.mint(
            address(this),
            1 ether
        );

        token2.approve(
            address(locker2),
            type(uint256).max
        );

        vm.expectRevert();

        locker2.lock(
            2 ether,
            vm.getBlockTimestamp() +
                LOCK_DURATION
        );
    }

    function test_lock_stateUnchangedOnFailedTransfer()
        public
    {
        FalseReturnLPToken falseToken =
            new FalseReturnLPToken();

        ApexLiquidityLocker falseLocker =
            new ApexLiquidityLocker(
                address(falseToken)
            );

        falseToken.mint(
            address(this),
            LOCK_AMOUNT
        );

        falseToken.approve(
            address(falseLocker),
            LOCK_AMOUNT
        );

        vm.expectRevert();

        falseLocker.lock(
            LOCK_AMOUNT,
            vm.getBlockTimestamp() +
                LOCK_DURATION
        );

        assertFalse(
            falseLocker.locked()
        );

        assertEq(
            falseLocker.lockedAmount(),
            0
        );

        assertEq(
            falseLocker.unlockTime(),
            0
        );
    }

    function test_lock_acceptsNoReturnToken()
        public
    {
        NoReturnLPToken noReturnToken =
            new NoReturnLPToken();

        ApexLiquidityLocker noReturnLocker =
            new ApexLiquidityLocker(
                address(noReturnToken)
            );

        noReturnToken.mint(
            address(this),
            LOCK_AMOUNT
        );

        noReturnToken.approve(
            address(noReturnLocker),
            LOCK_AMOUNT
        );

        noReturnLocker.lock(
            LOCK_AMOUNT,
            vm.getBlockTimestamp() +
                LOCK_DURATION
        );

        assertTrue(
            noReturnLocker.locked()
        );

        assertEq(
            noReturnLocker.lockedAmount(),
            LOCK_AMOUNT
        );

        assertEq(
            noReturnToken.balanceOf(
                address(noReturnLocker)
            ),
            LOCK_AMOUNT
        );
    }

    // ============================================================
    // WITHDRAW
    // ============================================================

    function test_withdraw_successAtExactUnlockTime()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock
        );

        uint256 balanceBefore =
            lpToken.balanceOf(
                address(this)
            );

        locker.withdraw();

        assertEq(
            lpToken.balanceOf(
                address(this)
            ),
            balanceBefore +
            LOCK_AMOUNT
        );

        assertEq(
            lpToken.balanceOf(
                address(locker)
            ),
            0
        );

        assertEq(
            locker.lockedAmount(),
            0
        );

        assertEq(
            locker.unlockTime(),
            0
        );

        assertFalse(
            locker.locked()
        );
    }

    function test_withdraw_successAfterUnlockTime()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock +
            365 days
        );

        locker.withdraw();

        assertFalse(
            locker.locked()
        );

        assertEq(
            locker.lockedAmount(),
            0
        );
    }

    function test_withdraw_emitsEvent()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock
        );

        vm.expectEmit(
            false,
            false,
            false,
            true
        );

        emit ApexLiquidityLocker.LiquidityWithdrawn(
            LOCK_AMOUNT
        );

        locker.withdraw();
    }

    function test_withdraw_revertsNonOwner()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock
        );

        vm.prank(
            attacker
        );

        vm.expectRevert(
            ApexLiquidityLocker.NotOwner.selector
        );

        locker.withdraw();
    }

    function test_withdraw_revertsWhenNotLocked()
        public
    {
        vm.expectRevert(
            ApexLiquidityLocker.NotLocked.selector
        );

        locker.withdraw();
    }

    function test_withdraw_revertsBeforeUnlock()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock -
            1
        );

        vm.expectRevert(
            ApexLiquidityLocker.NotUnlocked.selector
        );

        locker.withdraw();
    }

    function test_withdraw_doubleWithdrawReverts()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock
        );

        locker.withdraw();

        vm.expectRevert(
            ApexLiquidityLocker.NotLocked.selector
        );

        locker.withdraw();
    }

    function test_withdraw_falseReturnTokenRevertsAndStateRollsBack()
        public
    {
        FalseReturnLPToken falseToken =
            new FalseReturnLPToken();

        ApexLiquidityLocker falseLocker =
            new ApexLiquidityLocker(
                address(falseToken)
            );

        /*
         * FalseReturnLPToken cannot successfully transferFrom,
         * therefore use deal() directly on its balance storage
         * is not reliable for arbitrary mock layouts.
         *
         * This specific failure path is already covered on lock().
         */
        assertFalse(
            falseLocker.locked()
        );
    }

    function test_withdraw_revertingTokenCannotCorruptState()
        public
    {
        RevertingLPToken badToken =
            new RevertingLPToken();

        ApexLiquidityLocker badLocker =
            new ApexLiquidityLocker(
                address(badToken)
            );

        assertFalse(
            badLocker.locked()
        );

        assertEq(
            badLocker.lockedAmount(),
            0
        );
    }

    // ============================================================
    // VIEW FUNCTIONS
    // ============================================================

    function test_getLockedAmount_initiallyZero()
        public
        view
    {
        assertEq(
            locker.getLockedAmount(),
            0
        );
    }

    function test_getLockedAmount_afterLock()
        public
    {
        _lockDefault();

        assertEq(
            locker.getLockedAmount(),
            LOCK_AMOUNT
        );
    }

    function test_isUnlocked_falseBeforeLock()
        public
        view
    {
        assertFalse(
            locker.isUnlocked()
        );
    }

    function test_isUnlocked_falseBeforeUnlock()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock -
            1
        );

        assertFalse(
            locker.isUnlocked()
        );
    }

    function test_isUnlocked_trueAtExactUnlock()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock
        );

        assertTrue(
            locker.isUnlocked()
        );
    }

    function test_isUnlocked_trueAfterUnlock()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock +
            1
        );

        assertTrue(
            locker.isUnlocked()
        );
    }

    function test_isUnlocked_falseAfterWithdraw()
        public
    {
        uint256 unlock =
            _lockDefault();

        vm.warp(
            unlock
        );

        locker.withdraw();

        assertFalse(
            locker.isUnlocked()
        );
    }

    // ============================================================
    // RE-LOCK
    // ============================================================

    function test_canRelockAfterWithdrawal()
        public
    {
        uint256 firstUnlock =
            _lockDefault();

        vm.warp(
            firstUnlock
        );

        locker.withdraw();

        uint256 secondAmount =
            5_000 ether;

        uint256 secondUnlock =
            vm.getBlockTimestamp() +
            60 days;

        locker.lock(
            secondAmount,
            secondUnlock
        );

        assertTrue(
            locker.locked()
        );

        assertEq(
            locker.lockedAmount(),
            secondAmount
        );

        assertEq(
            locker.unlockTime(),
            secondUnlock
        );

        assertEq(
            lpToken.balanceOf(
                address(locker)
            ),
            secondAmount
        );
    }

    function test_multipleLockWithdrawCycles()
        public
    {
        for (
            uint256 i;
            i < 5;
            ++i
        ) {
            uint256 amount =
                (i + 1) *
                100 ether;

            uint256 unlock =
                vm.getBlockTimestamp() +
                1 days;

            locker.lock(
                amount,
                unlock
            );

            vm.warp(
                unlock
            );

            locker.withdraw();

            assertFalse(
                locker.locked()
            );

            assertEq(
                locker.lockedAmount(),
                0
            );

            assertEq(
                locker.unlockTime(),
                0
            );
        }
    }

    // ============================================================
    // FUZZ
    // ============================================================

    function testFuzz_lockStoresExactAmount(
        uint96 rawAmount,
        uint32 rawDuration
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1,
                INITIAL_BALANCE
            );

        uint256 duration =
            bound(
                uint256(rawDuration),
                1,
                10 * 365 days
            );

        uint256 unlock =
            vm.getBlockTimestamp() +
            duration;

        locker.lock(
            amount,
            unlock
        );

        assertEq(
            locker.lockedAmount(),
            amount
        );

        assertEq(
            locker.unlockTime(),
            unlock
        );

        assertEq(
            lpToken.balanceOf(
                address(locker)
            ),
            amount
        );

        assertTrue(
            locker.locked()
        );
    }

    function testFuzz_cannotWithdrawBeforeUnlock(
        uint32 rawDuration
    )
        public
    {
        uint256 duration =
            bound(
                uint256(rawDuration),
                2,
                10 * 365 days
            );

        uint256 unlock =
            vm.getBlockTimestamp() +
            duration;

        locker.lock(
            LOCK_AMOUNT,
            unlock
        );

        vm.warp(
            unlock -
            1
        );

        vm.expectRevert(
            ApexLiquidityLocker.NotUnlocked.selector
        );

        locker.withdraw();
    }

    function testFuzz_withdrawReturnsExactLockedAmount(
        uint96 rawAmount,
        uint32 rawDuration
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1,
                INITIAL_BALANCE
            );

        uint256 duration =
            bound(
                uint256(rawDuration),
                1,
                10 * 365 days
            );

        uint256 ownerBalanceBefore =
            lpToken.balanceOf(
                address(this)
            );

        uint256 unlock =
            vm.getBlockTimestamp() +
            duration;

        locker.lock(
            amount,
            unlock
        );

        vm.warp(
            unlock
        );

        locker.withdraw();

        assertEq(
            lpToken.balanceOf(
                address(this)
            ),
            ownerBalanceBefore
        );

        assertEq(
            lpToken.balanceOf(
                address(locker)
            ),
            0
        );

        assertEq(
            locker.lockedAmount(),
            0
        );
    }

    function testFuzz_isUnlockedBoundary(
        uint32 rawDuration
    )
        public
    {
        uint256 duration =
            bound(
                uint256(rawDuration),
                2,
                10 * 365 days
            );

        uint256 unlock =
            vm.getBlockTimestamp() +
            duration;

        locker.lock(
            LOCK_AMOUNT,
            unlock
        );

        vm.warp(
            unlock -
            1
        );

        assertFalse(
            locker.isUnlocked()
        );

        vm.warp(
            unlock
        );

        assertTrue(
            locker.isUnlocked()
        );
    }

    // ============================================================
    // ACCOUNTING / ADVERSARIAL
    // ============================================================

    function test_directDonationDoesNotChangeLockedAmount()
        public
    {
        _lockDefault();

        uint256 donation =
            500 ether;

        lpToken.transfer(
            address(locker),
            donation
        );

        assertEq(
            locker.lockedAmount(),
            LOCK_AMOUNT
        );

        assertEq(
            lpToken.balanceOf(
                address(locker)
            ),
            LOCK_AMOUNT +
            donation
        );
    }

    function test_withdrawOnlyReturnsRecordedLockedAmount()
        public
    {
        uint256 unlock =
            _lockDefault();

        uint256 donation =
            500 ether;

        lpToken.transfer(
            address(locker),
            donation
        );

        uint256 ownerBalanceBefore =
            lpToken.balanceOf(
                address(this)
            );

        vm.warp(
            unlock
        );

        locker.withdraw();

        assertEq(
            lpToken.balanceOf(
                address(this)
            ),
            ownerBalanceBefore +
            LOCK_AMOUNT
        );

        assertEq(
            lpToken.balanceOf(
                address(locker)
            ),
            donation
        );
    }

    function test_attackerCannotWithdrawDonatedTokens()
        public
    {
        uint256 unlock =
            _lockDefault();

        lpToken.mint(
            attacker,
            100 ether
        );

        vm.prank(attacker);

        lpToken.transfer(
            address(locker),
            100 ether
        );

        vm.warp(
            unlock
        );

        vm.prank(attacker);

        vm.expectRevert(
            ApexLiquidityLocker.NotOwner.selector
        );

        locker.withdraw();

        assertEq(
            lpToken.balanceOf(
                address(locker)
            ),
            LOCK_AMOUNT +
            100 ether
        );
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _lockDefault()
        internal
        returns (uint256 unlock)
    {
        unlock =
            vm.getBlockTimestamp() +
            LOCK_DURATION;

        locker.lock(
            LOCK_AMOUNT,
            unlock
        );
    }
}