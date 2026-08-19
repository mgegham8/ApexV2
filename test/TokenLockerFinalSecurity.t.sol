// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {
    TokenLocker
} from "../src/contracts/token/TokenLocker.sol";

import {
    MockERC20
} from "../src/contracts/test/MockERC20.sol";

import {
    NoReturnERC20
} from "../src/contracts/test/NoReturnERC20.sol";

import {
    FalseReturnERC20
} from "../src/contracts/test/FalseReturnERC20.sol";

import {
    MockFeeToken
} from "../src/contracts/test/MockFeeToken.sol";


contract RevertingLockerToken {
    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] +=
            amount;
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
        revert(
            "TRANSFER_REVERT"
        );
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
        revert(
            "TRANSFER_FROM_REVERT"
        );
    }
}


contract ZeroTransferLockerToken {
    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] +=
            amount;
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
        return true;
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
        return true;
    }
}


contract ReentrantLockerToken {
    TokenLocker public immutable locker;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    bool public attackEnabled;

    uint256 public targetLockId;

    constructor(
        TokenLocker _locker
    ) {
        locker =
            _locker;
    }

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] +=
            amount;
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

    function setAttack(
        bool enabled,
        uint256 lockId
    )
        external
    {
        attackEnabled =
            enabled;

        targetLockId =
            lockId;
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        require(
            balanceOf[msg.sender] >= amount,
            "BALANCE_LOW"
        );

        balanceOf[msg.sender] -=
            amount;

        balanceOf[to] +=
            amount;

        if (
            attackEnabled &&
            msg.sender ==
                address(locker)
        ) {
            locker.unlock(
                targetLockId
            );
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        uint256 allowed =
            allowance[from][msg.sender];

        require(
            allowed >= amount,
            "ALLOWANCE_LOW"
        );

        require(
            balanceOf[from] >= amount,
            "BALANCE_LOW"
        );

        if (
            allowed !=
            type(uint256).max
        ) {
            allowance[from][msg.sender] =
                allowed - amount;
        }

        balanceOf[from] -=
            amount;

        balanceOf[to] +=
            amount;

        return true;
    }
}


contract TokenLockerFinalSecurityTest is Test {

    TokenLocker internal locker;

    MockERC20 internal token;

    address internal alice;
    address internal bob;
    address internal attacker;

    uint256 internal constant INITIAL_BALANCE =
        1_000_000 ether;


    function setUp()
        public
    {
        alice =
            makeAddr("alice");

        bob =
            makeAddr("bob");

        attacker =
            makeAddr("attacker");

        locker =
            new TokenLocker();

        token =
            new MockERC20(
                "Mock Token",
                "MOCK"
            );

        token.mint(
            alice,
            INITIAL_BALANCE
        );

        token.mint(
            bob,
            INITIAL_BALANCE
        );
    }


    // =============================================================
    // INITIAL STATE
    // =============================================================

    function test_initialNextLockIdIsOne()
        public
        view
    {
        assertEq(
            locker.nextLockId(),
            1
        );
    }


    function test_getLock_unknownIdReturnsEmpty()
        public
        view
    {
        (
            address lockToken,
            address owner,
            uint256 amount,
            uint256 unlockTime,
            bool claimed
        ) =
            locker.getLock(
                999
            );

        assertEq(
            lockToken,
            address(0)
        );

        assertEq(
            owner,
            address(0)
        );

        assertEq(
            amount,
            0
        );

        assertEq(
            unlockTime,
            0
        );

        assertFalse(
            claimed
        );
    }


    // =============================================================
    // LOCK VALIDATION
    // =============================================================

    function test_lock_revertsZeroToken()
        public
    {
        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .ZeroToken
                .selector
        );

        locker.lockTokens(
            address(0),
            100 ether,
            block.timestamp +
                1 days
        );
    }


    function test_lock_revertsZeroAmount()
        public
    {
        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .ZeroAmount
                .selector
        );

        locker.lockTokens(
            address(token),
            0,
            block.timestamp +
                1 days
        );
    }


    function test_lock_revertsUnlockTimeNow()
        public
    {
        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .InvalidUnlockTime
                .selector
        );

        locker.lockTokens(
            address(token),
            100 ether,
            block.timestamp
        );
    }


    function test_lock_revertsUnlockTimePast()
        public
    {
        vm.warp(
            10 days
        );

        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .InvalidUnlockTime
                .selector
        );

        locker.lockTokens(
            address(token),
            100 ether,
            block.timestamp -
                1
        );
    }


    function test_lock_revertsWithoutAllowance()
        public
    {
        vm.prank(alice);

        vm.expectRevert();

        locker.lockTokens(
            address(token),
            100 ether,
            block.timestamp +
                1 days
        );
    }


    function test_lock_revertsInsufficientBalance()
        public
    {
        uint256 amount =
            INITIAL_BALANCE +
            1;

        vm.prank(alice);

        token.approve(
            address(locker),
            amount
        );

        vm.prank(alice);

        vm.expectRevert();

        locker.lockTokens(
            address(token),
            amount,
            block.timestamp +
                1 days
        );
    }


    // =============================================================
    // SUCCESSFUL LOCK
    // =============================================================

    function test_lock_success()
        public
    {
        uint256 amount =
            100 ether;

        uint256 unlockTime =
            block.timestamp +
            30 days;

        vm.prank(alice);

        token.approve(
            address(locker),
            amount
        );

        vm.prank(alice);

        uint256 lockId =
            locker.lockTokens(
                address(token),
                amount,
                unlockTime
            );

        assertEq(
            lockId,
            1
        );

        assertEq(
            locker.nextLockId(),
            2
        );

        (
            address lockToken,
            address owner,
            uint256 storedAmount,
            uint256 storedUnlockTime,
            bool claimed
        ) =
            locker.getLock(
                lockId
            );

        assertEq(
            lockToken,
            address(token)
        );

        assertEq(
            owner,
            alice
        );

        assertEq(
            storedAmount,
            amount
        );

        assertEq(
            storedUnlockTime,
            unlockTime
        );

        assertFalse(
            claimed
        );

        assertEq(
            token.balanceOf(
                address(locker)
            ),
            amount
        );

        assertEq(
            token.balanceOf(alice),
            INITIAL_BALANCE -
                amount
        );
    }


    function test_lock_emitsEvent()
        public
    {
        uint256 amount =
            100 ether;

        uint256 unlockTime =
            block.timestamp +
            30 days;

        vm.prank(alice);

        token.approve(
            address(locker),
            amount
        );

        vm.expectEmit(
            true,
            true,
            true,
            true
        );

        emit TokenLocker.Locked(
            1,
            address(token),
            alice,
            amount,
            unlockTime
        );

        vm.prank(alice);

        locker.lockTokens(
            address(token),
            amount,
            unlockTime
        );
    }


    function test_multipleLocksIncrementIds()
        public
    {
        vm.startPrank(alice);

        token.approve(
            address(locker),
            300 ether
        );

        uint256 id1 =
            locker.lockTokens(
                address(token),
                100 ether,
                block.timestamp +
                    1 days
            );

        uint256 id2 =
            locker.lockTokens(
                address(token),
                200 ether,
                block.timestamp +
                    2 days
            );

        vm.stopPrank();

        assertEq(
            id1,
            1
        );

        assertEq(
            id2,
            2
        );

        assertEq(
            locker.nextLockId(),
            3
        );
    }


    function test_multipleUsersIndependentLocks()
        public
    {
        vm.prank(alice);

        token.approve(
            address(locker),
            100 ether
        );

        vm.prank(bob);

        token.approve(
            address(locker),
            200 ether
        );

        vm.prank(alice);

        uint256 aliceLock =
            locker.lockTokens(
                address(token),
                100 ether,
                block.timestamp +
                    1 days
            );

        vm.prank(bob);

        uint256 bobLock =
            locker.lockTokens(
                address(token),
                200 ether,
                block.timestamp +
                    2 days
            );

        (
            ,
            address owner1,
            uint256 amount1,
            ,
            
        ) =
            locker.getLock(
                aliceLock
            );

        (
            ,
            address owner2,
            uint256 amount2,
            ,
            
        ) =
            locker.getLock(
                bobLock
            );

        assertEq(
            owner1,
            alice
        );

        assertEq(
            owner2,
            bob
        );

        assertEq(
            amount1,
            100 ether
        );

        assertEq(
            amount2,
            200 ether
        );
    }


    // =============================================================
    // UNLOCK VALIDATION
    // =============================================================

    function test_unlock_revertsUnknownLock()
        public
    {
        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .LockNotFound
                .selector
        );

        locker.unlock(
            999
        );
    }


    function test_unlock_revertsNonOwner()
        public
    {
        uint256 lockId =
            _createLock(
                alice,
                100 ether,
                block.timestamp +
                    1 days
            );

        vm.warp(
            block.timestamp +
            2 days
        );

        vm.prank(attacker);

        vm.expectRevert(
            TokenLocker
                .NotLockOwner
                .selector
        );

        locker.unlock(
            lockId
        );
    }


    function test_unlock_revertsBeforeUnlockTime()
        public
    {
        uint256 unlockTime =
            block.timestamp +
            10 days;

        uint256 lockId =
            _createLock(
                alice,
                100 ether,
                unlockTime
            );

        vm.warp(
            unlockTime -
            1
        );

        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .StillLocked
                .selector
        );

        locker.unlock(
            lockId
        );
    }


    function test_unlock_successAtExactUnlockTime()
        public
    {
        uint256 amount =
            100 ether;

        uint256 unlockTime =
            block.timestamp +
            10 days;

        uint256 lockId =
            _createLock(
                alice,
                amount,
                unlockTime
            );

        uint256 balanceBefore =
            token.balanceOf(
                alice
            );

        vm.warp(
            unlockTime
        );

        vm.prank(alice);

        locker.unlock(
            lockId
        );

        assertEq(
            token.balanceOf(alice),
            balanceBefore +
                amount
        );

        (
            ,
            ,
            ,
            ,
            bool claimed
        ) =
            locker.getLock(
                lockId
            );

        assertTrue(
            claimed
        );
    }


    function test_unlock_successAfterUnlockTime()
        public
    {
        uint256 amount =
            100 ether;

        uint256 unlockTime =
            block.timestamp +
            10 days;

        uint256 lockId =
            _createLock(
                alice,
                amount,
                unlockTime
            );

        vm.warp(
            unlockTime +
            100 days
        );

        uint256 beforeBalance =
            token.balanceOf(
                alice
            );

        vm.prank(alice);

        locker.unlock(
            lockId
        );

        assertEq(
            token.balanceOf(alice),
            beforeBalance +
                amount
        );
    }


    function test_unlock_emitsEvent()
        public
    {
        uint256 amount =
            100 ether;

        uint256 unlockTime =
            block.timestamp +
            1 days;

        uint256 lockId =
            _createLock(
                alice,
                amount,
                unlockTime
            );

        vm.warp(
            unlockTime
        );

        vm.expectEmit(
            true,
            true,
            false,
            true
        );

        emit TokenLocker.Unlocked(
            lockId,
            alice,
            amount
        );

        vm.prank(alice);

        locker.unlock(
            lockId
        );
    }


    function test_unlock_doubleUnlockReverts()
        public
    {
        uint256 unlockTime =
            block.timestamp +
            1 days;

        uint256 lockId =
            _createLock(
                alice,
                100 ether,
                unlockTime
            );

        vm.warp(
            unlockTime
        );

        vm.prank(alice);

        locker.unlock(
            lockId
        );

        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .AlreadyClaimed
                .selector
        );

        locker.unlock(
            lockId
        );
    }


    // =============================================================
    // DONATION ACCOUNTING
    // =============================================================

    function test_directDonationDoesNotChangeRecordedLockAmount()
        public
    {
        uint256 amount =
            100 ether;

        uint256 lockId =
            _createLock(
                alice,
                amount,
                block.timestamp +
                    1 days
            );

        token.mint(
            address(locker),
            500 ether
        );

        (
            ,
            ,
            uint256 storedAmount,
            ,
            
        ) =
            locker.getLock(
                lockId
            );

        assertEq(
            storedAmount,
            amount
        );

        assertEq(
            token.balanceOf(
                address(locker)
            ),
            600 ether
        );
    }


    function test_unlockOnlyReturnsRecordedAmount()
        public
    {
        uint256 amount =
            100 ether;

        uint256 unlockTime =
            block.timestamp +
            1 days;

        uint256 lockId =
            _createLock(
                alice,
                amount,
                unlockTime
            );

        token.mint(
            address(locker),
            500 ether
        );

        uint256 beforeBalance =
            token.balanceOf(
                alice
            );

        vm.warp(
            unlockTime
        );

        vm.prank(alice);

        locker.unlock(
            lockId
        );

        assertEq(
            token.balanceOf(alice),
            beforeBalance +
                amount
        );

        assertEq(
            token.balanceOf(
                address(locker)
            ),
            500 ether
        );
    }


    // =============================================================
    // FEE-ON-TRANSFER ACCOUNTING
    // =============================================================

    function test_feeTokenStoresActualReceivedAmount()
        public
    {
        MockFeeToken feeToken =
            new MockFeeToken();

        uint256 amount =
            1_000 ether;

        feeToken.mint(
            alice,
            amount
        );

        vm.prank(alice);

        feeToken.approve(
            address(locker),
            amount
        );

        vm.prank(alice);

        uint256 lockId =
            locker.lockTokens(
                address(feeToken),
                amount,
                block.timestamp +
                    1 days
            );

        uint256 actualReceived =
            feeToken.balanceOf(
                address(locker)
            );

        (
            ,
            ,
            uint256 storedAmount,
            ,
            
        ) =
            locker.getLock(
                lockId
            );

        assertEq(
            storedAmount,
            actualReceived
        );

        assertLt(
            actualReceived,
            amount
        );

        assertGt(
            actualReceived,
            0
        );
    }


    // =============================================================
    // NO RETURN TOKEN
    // =============================================================

    function test_lock_acceptsNoReturnToken()
        public
    {
        NoReturnERC20 noReturnToken =
            new NoReturnERC20();

        uint256 amount =
            100 ether;

        noReturnToken.mint(
            alice,
            amount
        );

        vm.prank(alice);

        noReturnToken.approve(
            address(locker),
            amount
        );

        vm.prank(alice);

        uint256 lockId =
            locker.lockTokens(
                address(noReturnToken),
                amount,
                block.timestamp +
                    1 days
            );

        (
            address lockToken,
            address owner,
            uint256 storedAmount,
            ,
            
        ) =
            locker.getLock(
                lockId
            );

        assertEq(
            lockToken,
            address(noReturnToken)
        );

        assertEq(
            owner,
            alice
        );

        assertEq(
            storedAmount,
            amount
        );
    }


    // =============================================================
    // FALSE RETURN TOKEN
    // =============================================================

    function test_lock_revertsFalseReturnToken()
        public
    {
        FalseReturnERC20 falseToken =
            new FalseReturnERC20();

        uint256 amount =
            100 ether;

        falseToken.mint(
            alice,
            amount
        );

        vm.prank(alice);

        falseToken.approve(
            address(locker),
            amount
        );

        vm.prank(alice);

        vm.expectRevert();

        locker.lockTokens(
            address(falseToken),
            amount,
            block.timestamp +
                1 days
        );

        assertEq(
            locker.nextLockId(),
            1
        );
    }


    // =============================================================
    // REVERTING TOKEN
    // =============================================================

    function test_lock_revertingTokenDoesNotCreateLock()
        public
    {
        RevertingLockerToken badToken =
            new RevertingLockerToken();

        badToken.mint(
            alice,
            100 ether
        );

        vm.prank(alice);

        badToken.approve(
            address(locker),
            100 ether
        );

        vm.prank(alice);

        vm.expectRevert();

        locker.lockTokens(
            address(badToken),
            100 ether,
            block.timestamp +
                1 days
        );

        assertEq(
            locker.nextLockId(),
            1
        );

        (
            address lockToken,
            address owner,
            uint256 amount,
            uint256 unlockTime,
            bool claimed
        ) =
            locker.getLock(
                1
            );

        assertEq(
            lockToken,
            address(0)
        );

        assertEq(
            owner,
            address(0)
        );

        assertEq(
            amount,
            0
        );

        assertEq(
            unlockTime,
            0
        );

        assertFalse(
            claimed
        );
    }


    // =============================================================
    // ZERO RECEIVED TOKEN
    // =============================================================

    function test_lock_revertsWhenTokenReportsNoBalanceIncrease()
        public
    {
        ZeroTransferLockerToken zeroToken =
            new ZeroTransferLockerToken();

        zeroToken.mint(
            alice,
            100 ether
        );

        vm.prank(alice);

        zeroToken.approve(
            address(locker),
            100 ether
        );

        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .ZeroReceived
                .selector
        );

        locker.lockTokens(
            address(zeroToken),
            100 ether,
            block.timestamp +
                1 days
        );

        assertEq(
            locker.nextLockId(),
            1
        );
    }


    // =============================================================
    // FAILED WITHDRAW ROLLBACK
    // =============================================================

    function test_failedUnlockRollsBackClaimedState()
        public
    {
    

        /*
         * RevertingLockerToken cannot be locked through transferFrom,
         * therefore this behavior requires a separate token that
         * succeeds during lock and fails during transfer.
         */
        ToggleTransferToken toggleToken =
            new ToggleTransferToken();

        toggleToken.mint(
            alice,
            100 ether
        );

        vm.prank(alice);

        toggleToken.approve(
            address(locker),
            100 ether
        );

        vm.prank(alice);

        uint256 lockId =
            locker.lockTokens(
                address(toggleToken),
                100 ether,
                block.timestamp +
                    1 days
            );

        toggleToken.setFailTransfer(
            true
        );

        vm.warp(
            block.timestamp +
            2 days
        );

        vm.prank(alice);

        vm.expectRevert();

        locker.unlock(
            lockId
        );

        (
            ,
            ,
            uint256 amount,
            ,
            bool claimed
        ) =
            locker.getLock(
                lockId
            );

        assertEq(
            amount,
            100 ether
        );

        assertFalse(
            claimed
        );
    }


    // =============================================================
    // FUZZ
    // =============================================================

    function testFuzz_lockStoresExactAmount(
        uint96 rawAmount,
        uint32 rawDelay
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1,
                INITIAL_BALANCE
            );

        uint256 delay =
            bound(
                uint256(rawDelay),
                1,
                3650 days
            );

        uint256 unlockTime =
            block.timestamp +
            delay;

        vm.prank(alice);

        token.approve(
            address(locker),
            amount
        );

        vm.prank(alice);

        uint256 lockId =
            locker.lockTokens(
                address(token),
                amount,
                unlockTime
            );

        (
            address storedToken,
            address owner,
            uint256 storedAmount,
            uint256 storedUnlockTime,
            bool claimed
        ) =
            locker.getLock(
                lockId
            );

        assertEq(
            storedToken,
            address(token)
        );

        assertEq(
            owner,
            alice
        );

        assertEq(
            storedAmount,
            amount
        );

        assertEq(
            storedUnlockTime,
            unlockTime
        );

        assertFalse(
            claimed
        );
    }


    function testFuzz_cannotUnlockBeforeTimestamp(
        uint96 rawAmount,
        uint32 rawDelay
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1,
                INITIAL_BALANCE
            );

        uint256 delay =
            bound(
                uint256(rawDelay),
                2,
                3650 days
            );

        uint256 unlockTime =
            block.timestamp +
            delay;

        uint256 lockId =
            _createLock(
                alice,
                amount,
                unlockTime
            );

        vm.warp(
            unlockTime -
            1
        );

        vm.prank(alice);

        vm.expectRevert(
            TokenLocker
                .StillLocked
                .selector
        );

        locker.unlock(
            lockId
        );
    }


    function testFuzz_unlockReturnsExactAmount(
        uint96 rawAmount,
        uint32 rawDelay
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                1,
                INITIAL_BALANCE
            );

        uint256 delay =
            bound(
                uint256(rawDelay),
                1,
                3650 days
            );

        uint256 unlockTime =
            block.timestamp +
            delay;

        uint256 lockId =
            _createLock(
                alice,
                amount,
                unlockTime
            );

        uint256 balanceBefore =
            token.balanceOf(
                alice
            );

        vm.warp(
            unlockTime
        );

        vm.prank(alice);

        locker.unlock(
            lockId
        );

        assertEq(
            token.balanceOf(alice),
            balanceBefore +
                amount
        );
    }


    // =============================================================
    // INTERNAL HELPERS
    // =============================================================

    function _createLock(
        address owner,
        uint256 amount,
        uint256 unlockTime
    )
        internal
        returns (uint256 lockId)
    {
        vm.prank(owner);

        token.approve(
            address(locker),
            amount
        );

        vm.prank(owner);

        lockId =
            locker.lockTokens(
                address(token),
                amount,
                unlockTime
            );
    }
}


contract ToggleTransferToken {
    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    bool public failTransfer;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] +=
            amount;
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

    function setFailTransfer(
        bool value
    )
        external
    {
        failTransfer =
            value;
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        if (
            failTransfer
        ) {
            return false;
        }

        require(
            balanceOf[msg.sender] >= amount,
            "BALANCE_LOW"
        );

        balanceOf[msg.sender] -=
            amount;

        balanceOf[to] +=
            amount;

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        uint256 allowed =
            allowance[from][msg.sender];

        require(
            allowed >= amount,
            "ALLOWANCE_LOW"
        );

        require(
            balanceOf[from] >= amount,
            "BALANCE_LOW"
        );

        if (
            allowed !=
            type(uint256).max
        ) {
            allowance[from][msg.sender] =
                allowed - amount;
        }

        balanceOf[from] -=
            amount;

        balanceOf[to] +=
            amount;

        return true;
    }
}