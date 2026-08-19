// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {
    VotingToken
} from "../src/contracts/governance/VotingToken.sol";

contract VotingTokenFinalSecurityTest is Test {
    VotingToken internal token;

    uint256 internal ownerPk;
    uint256 internal alicePk;
    uint256 internal bobPk;

    address internal owner;
    address internal alice;
    address internal bob;
    address internal carol;
    address internal attacker;

    uint256 internal constant INITIAL_SUPPLY =
        1_000_000 ether;

    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    bytes32 internal constant DELEGATION_TYPEHASH =
        keccak256(
            "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
        );

    function setUp() public {
        ownerPk = 0xA11CE;
        alicePk = 0xB0B;
        bobPk = 0xCAFE;

        owner =
            vm.addr(ownerPk);

        alice =
            vm.addr(alicePk);

        bob =
            vm.addr(bobPk);

        carol =
            makeAddr("carol");

        attacker =
            makeAddr("attacker");

        vm.prank(owner);

        token =
            new VotingToken();
    }

    // ============================================================
    // METADATA / INITIAL STATE
    // ============================================================

    function test_metadata()
        public
        view
    {
        assertEq(
            token.name(),
            "Apex Voting Token"
        );

        assertEq(
            token.symbol(),
            "AVT"
        );

        assertEq(
            token.decimals(),
            18
        );
    }

    function test_constructor_mintsInitialSupply()
        public
        view
    {
        assertEq(
            token.totalSupply(),
            INITIAL_SUPPLY
        );

        assertEq(
            token.balanceOf(owner),
            INITIAL_SUPPLY
        );
    }

    function test_constructor_onlyMintsToDeployer()
        public
        view
    {
        assertEq(
            token.balanceOf(alice),
            0
        );

        assertEq(
            token.balanceOf(bob),
            0
        );
    }

    // ============================================================
    // CLOCK
    // ============================================================

    function test_clock_matchesBlockNumber()
        public
        view
    {
        assertEq(
            uint256(token.clock()),
            block.number
        );
    }

    function test_CLOCK_MODE()
        public
        view
    {
        assertEq(
            token.CLOCK_MODE(),
            "mode=blocknumber&from=default"
        );
    }

    function test_clock_updatesAfterBlockRoll()
        public
    {
        uint256 targetBlock =
            block.number + 100;

        vm.roll(
            targetBlock
        );

        assertEq(
            uint256(token.clock()),
            targetBlock
        );
    }

    // ============================================================
    // TRANSFER
    // ============================================================

    function test_transfer_success()
        public
    {
        uint256 amount =
            100 ether;

        vm.prank(owner);

        bool success =
            token.transfer(
                alice,
                amount
            );

        assertTrue(
            success
        );

        assertEq(
            token.balanceOf(owner),
            INITIAL_SUPPLY -
                amount
        );

        assertEq(
            token.balanceOf(alice),
            amount
        );
    }

    function test_transfer_exactBalance()
        public
    {
        vm.prank(owner);

        token.transfer(
            alice,
            INITIAL_SUPPLY
        );

        assertEq(
            token.balanceOf(owner),
            0
        );

        assertEq(
            token.balanceOf(alice),
            INITIAL_SUPPLY
        );
    }

    function test_transfer_revertsInsufficientBalance()
        public
    {
        vm.prank(alice);

        vm.expectRevert();

        token.transfer(
            bob,
            1
        );
    }

    function test_transfer_revertsZeroRecipient()
        public
    {
        vm.prank(owner);

        vm.expectRevert();

        token.transfer(
            address(0),
            1 ether
        );
    }

    // ============================================================
    // APPROVAL / TRANSFER FROM
    // ============================================================

    function test_approve_success()
        public
    {
        uint256 amount =
            500 ether;

        vm.prank(owner);

        bool success =
            token.approve(
                alice,
                amount
            );

        assertTrue(
            success
        );

        assertEq(
            token.allowance(
                owner,
                alice
            ),
            amount
        );
    }

    function test_transferFrom_success()
        public
    {
        uint256 amount =
            100 ether;

        vm.prank(owner);

        token.approve(
            alice,
            amount
        );

        vm.prank(alice);

        token.transferFrom(
            owner,
            bob,
            amount
        );

        assertEq(
            token.balanceOf(bob),
            amount
        );

        assertEq(
            token.allowance(
                owner,
                alice
            ),
            0
        );
    }

    function test_transferFrom_revertsInsufficientAllowance()
        public
    {
        vm.prank(alice);

        vm.expectRevert();

        token.transferFrom(
            owner,
            bob,
            1 ether
        );
    }

    function test_infiniteAllowanceDoesNotDecrease()
        public
    {
        vm.prank(owner);

        token.approve(
            alice,
            type(uint256).max
        );

        vm.prank(alice);

        token.transferFrom(
            owner,
            bob,
            100 ether
        );

        assertEq(
            token.allowance(
                owner,
                alice
            ),
            type(uint256).max
        );
    }

    // ============================================================
    // DELEGATION
    // ============================================================

    function test_initialVotesAreZeroWithoutDelegation()
        public
        view
    {
        assertEq(
            token.getVotes(owner),
            0
        );
    }

    function test_selfDelegationActivatesVotingPower()
        public
    {
        vm.prank(owner);

        token.delegate(
            owner
        );

        assertEq(
            token.delegates(owner),
            owner
        );

        assertEq(
            token.getVotes(owner),
            INITIAL_SUPPLY
        );
    }

    function test_delegateToAnotherAccount()
        public
    {
        vm.prank(owner);

        token.delegate(
            alice
        );

        assertEq(
            token.delegates(owner),
            alice
        );

        assertEq(
            token.getVotes(alice),
            INITIAL_SUPPLY
        );

        assertEq(
            token.getVotes(owner),
            0
        );
    }

    function test_redelegationMovesVotingPower()
        public
    {
        vm.prank(owner);

        token.delegate(
            alice
        );

        assertEq(
            token.getVotes(alice),
            INITIAL_SUPPLY
        );

        vm.prank(owner);

        token.delegate(
            bob
        );

        assertEq(
            token.getVotes(alice),
            0
        );

        assertEq(
            token.getVotes(bob),
            INITIAL_SUPPLY
        );
    }

    function test_transferUpdatesVotesWhenDelegated()
        public
    {
        vm.prank(owner);

        token.delegate(
            owner
        );

        assertEq(
            token.getVotes(owner),
            INITIAL_SUPPLY
        );

        uint256 amount =
            100_000 ether;

        vm.prank(owner);

        token.transfer(
            alice,
            amount
        );

        assertEq(
            token.getVotes(owner),
            INITIAL_SUPPLY -
                amount
        );

        assertEq(
            token.getVotes(alice),
            0
        );

        vm.prank(alice);

        token.delegate(
            alice
        );

        assertEq(
            token.getVotes(alice),
            amount
        );
    }

    function test_transferBetweenDelegatedAccountsMovesVotes()
        public
    {
        uint256 amount =
            100_000 ether;

        vm.prank(owner);

        token.transfer(
            alice,
            amount
        );

        vm.prank(owner);

        token.delegate(
            owner
        );

        vm.prank(alice);

        token.delegate(
            alice
        );

        assertEq(
            token.getVotes(owner),
            INITIAL_SUPPLY -
                amount
        );

        assertEq(
            token.getVotes(alice),
            amount
        );

        uint256 transferAmount =
            10_000 ether;

        vm.prank(alice);

        token.transfer(
            owner,
            transferAmount
        );

        assertEq(
            token.getVotes(owner),
            INITIAL_SUPPLY -
                amount +
                transferAmount
        );

        assertEq(
            token.getVotes(alice),
            amount -
                transferAmount
        );
    }

    function test_multipleHoldersDelegateToSameDelegate()
        public
    {
        uint256 aliceAmount =
            100_000 ether;

        uint256 bobAmount =
            200_000 ether;

        vm.startPrank(owner);

        token.transfer(
            alice,
            aliceAmount
        );

        token.transfer(
            bob,
            bobAmount
        );

        token.delegate(
            carol
        );

        vm.stopPrank();

        vm.prank(alice);

        token.delegate(
            carol
        );

        vm.prank(bob);

        token.delegate(
            carol
        );

        assertEq(
            token.getVotes(carol),
            INITIAL_SUPPLY
        );
    }

    // ============================================================
    // CHECKPOINTS / PAST VOTES
    // ============================================================

    function test_getPastVotes_tracksHistoricalVotes()
        public
    {
        vm.prank(owner);

        token.delegate(
            owner
        );

        uint256 snapshotBlock =
            vm.getBlockNumber();

        vm.roll(
            snapshotBlock + 1
        );

        assertEq(
            vm.getBlockNumber(),
            snapshotBlock + 1
        );

        assertEq(
            token.getPastVotes(
                owner,
                snapshotBlock
            ),
            INITIAL_SUPPLY
        );

        vm.prank(owner);

        token.transfer(
            alice,
            100_000 ether
        );

        uint256 secondBlock =
            vm.getBlockNumber();

        assertEq(
            token.getVotes(owner),
            900_000 ether
        );

        vm.roll(
            secondBlock + 1
        );

        assertEq(
            vm.getBlockNumber(),
            secondBlock + 1
        );

        assertEq(
            token.getPastVotes(
                owner,
                snapshotBlock
            ),
            INITIAL_SUPPLY
        );

        assertEq(
            token.getPastVotes(
                owner,
                secondBlock
            ),
            900_000 ether
        );
    }

    function test_getPastVotes_revertsForCurrentBlock()
        public
    {
        vm.expectRevert();

        token.getPastVotes(
            owner,
            block.number
        );
    }

    function test_getPastVotes_revertsForFutureBlock()
        public
    {
        vm.expectRevert();

        token.getPastVotes(
            owner,
            block.number + 1
        );
    }

    function test_getPastTotalSupply_tracksSupply()
        public
    {
        uint256 snapshotBlock =
            vm.getBlockNumber();

        vm.roll(
            snapshotBlock + 1
        );

        assertEq(
            vm.getBlockNumber(),
            snapshotBlock + 1
        );

        assertEq(
            token.getPastTotalSupply(
                snapshotBlock
            ),
            INITIAL_SUPPLY
        );
    }

    function test_getPastTotalSupply_revertsCurrentBlock()
        public
    {
        vm.expectRevert();

        token.getPastTotalSupply(
            block.number
        );
    }

    // ============================================================
    // PERMIT
    // ============================================================

    function test_permit_success()
        public
    {
        uint256 value =
            5_000 ether;

        uint256 deadline =
            vm.getBlockTimestamp() +
            1 days;

        uint256 nonce =
            token.nonces(owner);

        bytes32 digest =
            _permitDigest(
                owner,
                alice,
                value,
                nonce,
                deadline
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        token.permit(
            owner,
            alice,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.allowance(
                owner,
                alice
            ),
            value
        );

        assertEq(
            token.nonces(owner),
            nonce + 1
        );
    }

    function test_permit_revertsExpired()
        public
    {
        uint256 deadline =
            vm.getBlockTimestamp() +
            1 days;

        uint256 nonce =
            token.nonces(owner);

        bytes32 digest =
            _permitDigest(
                owner,
                alice,
                100 ether,
                nonce,
                deadline
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        vm.warp(
            deadline + 1
        );

        vm.expectRevert();

        token.permit(
            owner,
            alice,
            100 ether,
            deadline,
            v,
            r,
            s
        );
    }

    function test_permit_revertsWrongSigner()
        public
    {
        uint256 deadline =
            vm.getBlockTimestamp() +
            1 days;

        uint256 nonce =
            token.nonces(owner);

        bytes32 digest =
            _permitDigest(
                owner,
                alice,
                100 ether,
                nonce,
                deadline
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                bobPk,
                digest
            );

        vm.expectRevert();

        token.permit(
            owner,
            alice,
            100 ether,
            deadline,
            v,
            r,
            s
        );
    }

    function test_permitCannotReplay()
        public
    {
        uint256 value =
            100 ether;

        uint256 deadline =
            vm.getBlockTimestamp() +
            1 days;

        uint256 nonce =
            token.nonces(owner);

        bytes32 digest =
            _permitDigest(
                owner,
                alice,
                value,
                nonce,
                deadline
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        token.permit(
            owner,
            alice,
            value,
            deadline,
            v,
            r,
            s
        );

        vm.expectRevert();

        token.permit(
            owner,
            alice,
            value,
            deadline,
            v,
            r,
            s
        );
    }

    function test_permitNonceOnlyIncrementsOnce()
        public
    {
        uint256 nonceBefore =
            token.nonces(owner);

        uint256 deadline =
            vm.getBlockTimestamp() +
            1 days;

        bytes32 digest =
            _permitDigest(
                owner,
                alice,
                1 ether,
                nonceBefore,
                deadline
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        token.permit(
            owner,
            alice,
            1 ether,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.nonces(owner),
            nonceBefore + 1
        );
    }

    // ============================================================
    // DELEGATE BY SIGNATURE
    // ============================================================

    function test_delegateBySig_success()
        public
    {
        uint256 nonce =
            token.nonces(owner);

        uint256 expiry =
            vm.getBlockTimestamp() +
            1 days;

        bytes32 structHash =
            keccak256(
                abi.encode(
                    DELEGATION_TYPEHASH,
                    alice,
                    nonce,
                    expiry
                )
            );

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    structHash
                )
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        token.delegateBySig(
            alice,
            nonce,
            expiry,
            v,
            r,
            s
        );

        assertEq(
            token.delegates(owner),
            alice
        );

        assertEq(
            token.getVotes(alice),
            INITIAL_SUPPLY
        );

        assertEq(
            token.nonces(owner),
            nonce + 1
        );
    }

    function test_delegateBySig_revertsExpired()
        public
    {
        uint256 nonce =
            token.nonces(owner);

        uint256 expiry =
            vm.getBlockTimestamp() +
            1 days;

        bytes32 digest =
            _delegationDigest(
                alice,
                nonce,
                expiry
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        vm.warp(
            expiry + 1
        );

        vm.expectRevert();

        token.delegateBySig(
            alice,
            nonce,
            expiry,
            v,
            r,
            s
        );
    }

    function test_delegateBySig_cannotReplay()
        public
    {
        uint256 nonce =
            token.nonces(owner);

        uint256 expiry =
            vm.getBlockTimestamp() +
            1 days;

        bytes32 digest =
            _delegationDigest(
                alice,
                nonce,
                expiry
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        token.delegateBySig(
            alice,
            nonce,
            expiry,
            v,
            r,
            s
        );

        vm.expectRevert();

        token.delegateBySig(
            alice,
            nonce,
            expiry,
            v,
            r,
            s
        );
    }

    function test_delegateBySig_revertsWrongNonce()
        public
    {
        uint256 actualNonce =
            token.nonces(owner);

        uint256 wrongNonce =
            actualNonce + 1;

        uint256 expiry =
            vm.getBlockTimestamp() +
            1 days;

        bytes32 digest =
            _delegationDigest(
                alice,
                wrongNonce,
                expiry
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        vm.expectRevert();

        token.delegateBySig(
            alice,
            wrongNonce,
            expiry,
            v,
            r,
            s
        );
    }

    // ============================================================
    // NONCES
    // ============================================================

    function test_nonceInitiallyZero()
        public
        view
    {
        assertEq(
            token.nonces(owner),
            0
        );
    }

    function test_permitAndDelegationShareNonceSpace()
        public
    {
        uint256 permitDeadline =
            vm.getBlockTimestamp() +
            1 days;

        uint256 nonce0 =
            token.nonces(owner);

        bytes32 permitDigest =
            _permitDigest(
                owner,
                alice,
                100 ether,
                nonce0,
                permitDeadline
            );

        (
            uint8 permitV,
            bytes32 permitR,
            bytes32 permitS
        ) =
            vm.sign(
                ownerPk,
                permitDigest
            );

        token.permit(
            owner,
            alice,
            100 ether,
            permitDeadline,
            permitV,
            permitR,
            permitS
        );

        assertEq(
            token.nonces(owner),
            nonce0 + 1
        );

        uint256 nonce1 =
            token.nonces(owner);

        uint256 expiry =
            vm.getBlockTimestamp() +
            1 days;

        bytes32 delegationDigest =
            _delegationDigest(
                bob,
                nonce1,
                expiry
            );

        (
            uint8 delegationV,
            bytes32 delegationR,
            bytes32 delegationS
        ) =
            vm.sign(
                ownerPk,
                delegationDigest
            );

        token.delegateBySig(
            bob,
            nonce1,
            expiry,
            delegationV,
            delegationR,
            delegationS
        );

        assertEq(
            token.nonces(owner),
            nonce1 + 1
        );

        assertEq(
            token.delegates(owner),
            bob
        );
    }

    // ============================================================
    // FUZZ - TRANSFERS
    // ============================================================

    function testFuzz_transfer(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                INITIAL_SUPPLY
            );

        vm.prank(owner);

        token.transfer(
            alice,
            amount
        );

        assertEq(
            token.balanceOf(alice),
            amount
        );

        assertEq(
            token.balanceOf(owner),
            INITIAL_SUPPLY -
                amount
        );

        assertEq(
            token.totalSupply(),
            INITIAL_SUPPLY
        );
    }

    function testFuzz_delegatedTransferPreservesTotalVotes(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                INITIAL_SUPPLY
            );

        vm.prank(owner);

        token.delegate(
            owner
        );

        vm.prank(owner);

        token.transfer(
            alice,
            amount
        );

        vm.prank(alice);

        token.delegate(
            alice
        );

        assertEq(
            token.getVotes(owner) +
                token.getVotes(alice),
            INITIAL_SUPPLY
        );
    }

    function testFuzz_multipleDelegatesPreserveVotes(
        uint96 rawAliceAmount,
        uint96 rawBobAmount
    )
        public
    {
        uint256 aliceAmount =
            bound(
                uint256(rawAliceAmount),
                0,
                INITIAL_SUPPLY
            );

        uint256 remaining =
            INITIAL_SUPPLY -
            aliceAmount;

        uint256 bobAmount =
            bound(
                uint256(rawBobAmount),
                0,
                remaining
            );

        vm.startPrank(owner);

        token.transfer(
            alice,
            aliceAmount
        );

        token.transfer(
            bob,
            bobAmount
        );

        token.delegate(
            owner
        );

        vm.stopPrank();

        vm.prank(alice);

        token.delegate(
            alice
        );

        vm.prank(bob);

        token.delegate(
            bob
        );

        assertEq(
            token.getVotes(owner) +
                token.getVotes(alice) +
                token.getVotes(bob),
            INITIAL_SUPPLY
        );
    }

    // ============================================================
    // FUZZ - PERMIT
    // ============================================================

    function testFuzz_permit(
        uint96 rawValue,
        uint32 rawDeadlineOffset
    )
        public
    {
        uint256 value =
            uint256(rawValue);

        uint256 offset =
            bound(
                uint256(rawDeadlineOffset),
                1,
                365 days
            );

        uint256 deadline =
            vm.getBlockTimestamp() +
            offset;

        uint256 nonce =
            token.nonces(owner);

        bytes32 digest =
            _permitDigest(
                owner,
                alice,
                value,
                nonce,
                deadline
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                ownerPk,
                digest
            );

        token.permit(
            owner,
            alice,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.allowance(
                owner,
                alice
            ),
            value
        );

        assertEq(
            token.nonces(owner),
            nonce + 1
        );
    }

    // ============================================================
    // FUZZ - HISTORICAL VOTES
    // ============================================================

    function testFuzz_pastVotesRemainImmutable(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                INITIAL_SUPPLY
            );

        vm.prank(owner);

        token.delegate(
            owner
        );

        uint256 snapshotBlock =
            vm.getBlockNumber();

        vm.roll(
            snapshotBlock + 1
        );

        assertEq(
            token.getPastVotes(
                owner,
                snapshotBlock
            ),
            INITIAL_SUPPLY
        );

        vm.prank(owner);

        token.transfer(
            alice,
            amount
        );

        uint256 transferBlock =
            vm.getBlockNumber();

        vm.roll(
            transferBlock + 1
        );

        assertEq(
            token.getPastVotes(
                owner,
                snapshotBlock
            ),
            INITIAL_SUPPLY
        );

        assertEq(
            token.getPastVotes(
                owner,
                transferBlock
            ),
            INITIAL_SUPPLY -
                amount
        );

        assertEq(
            token.getVotes(owner),
            INITIAL_SUPPLY -
                amount
        );
    }

    // ============================================================
    // DOMAIN SEPARATOR
    // ============================================================

    function test_DOMAIN_SEPARATOR_nonZero()
        public
        view
    {
        assertTrue(
            token.DOMAIN_SEPARATOR() !=
                bytes32(0)
        );
    }

    function test_DOMAIN_SEPARATOR_changesWithChainId()
        public
    {
        bytes32 original =
            token.DOMAIN_SEPARATOR();

        uint256 newChainId =
            block.chainid + 1;

        vm.chainId(
            newChainId
        );

        bytes32 changed =
            token.DOMAIN_SEPARATOR();

        assertTrue(
            changed != original
        );
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _permitDigest(
        address permitOwner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    permitOwner,
                    spender,
                    value,
                    nonce,
                    deadline
                )
            );

        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    structHash
                )
            );
    }

    function _delegationDigest(
        address delegatee,
        uint256 nonce,
        uint256 expiry
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    DELEGATION_TYPEHASH,
                    delegatee,
                    nonce,
                    expiry
                )
            );

        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    structHash
                )
            );
    }
}