// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {ApexGovernor} from "../src/contracts/governance/Governor.sol";

import {VotingToken} from "../src/contracts/governance/VotingToken.sol";

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

contract GovernorTarget {
    uint256 public value;
    address public lastCaller;

    function setValue(uint256 newValue) external {
        value = newValue;

        lastCaller = msg.sender;
    }

    function revertingCall() external pure {
        revert("TARGET_REVERT");
    }
}

contract GovernorFinalSecurityTest is Test {
    VotingToken internal token;
    TimelockController internal timelock;
    ApexGovernor internal governor;
    GovernorTarget internal target;

    address internal voter2;
    address internal attacker;

    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;

    uint256 internal constant MIN_DELAY = 2 days;

    uint256 internal constant VOTING_DELAY = 1;

    uint256 internal constant VOTING_PERIOD = 45_818;

    uint256 internal constant QUORUM = 40_000 ether;

    function setUp() public {
        voter2 = makeAddr("voter2");

        attacker = makeAddr("attacker");

        token = new VotingToken();

        address[] memory proposers = new address[](0);

        address[] memory executors = new address[](1);

        /*
         * address(0) executor makes execution permissionless
         * once an operation is ready.
         */
        executors[0] = address(0);

        timelock = new TimelockController(MIN_DELAY, proposers, executors, address(this));

        governor = new ApexGovernor(token, timelock);

        target = new GovernorTarget();

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));

        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));

        /*
         * ERC20Votes balances do not count as voting power
         * until delegated.
         */
        token.delegate(address(this));

        vm.deal(address(this), 100 ether);

        vm.deal(attacker, 100 ether);
    }

    // ============================================================
    // CONSTRUCTOR / SETTINGS
    // ============================================================

    function test_name() public view {
        assertEq(governor.name(), "ApexGovernor");
    }

    function test_version() public view {
        assertEq(governor.version(), "1");
    }

    function test_votingDelay() public view {
        assertEq(governor.votingDelay(), VOTING_DELAY);
    }

    function test_votingPeriod() public view {
        assertEq(governor.votingPeriod(), VOTING_PERIOD);
    }

    function test_proposalThreshold() public view {
        assertEq(governor.proposalThreshold(), 0);
    }

    function test_timelockAddress() public view {
        assertEq(governor.timelock(), address(timelock));
    }

    function test_quorumNumerator() public view {
        assertEq(governor.quorumNumerator(), 4);
    }

    function test_quorumDenominator() public view {
        assertEq(governor.quorumDenominator(), 100);
    }

    function test_CLOCK_MODE_matchesVotingToken() public view {
        assertEq(governor.CLOCK_MODE(), token.CLOCK_MODE());
    }

    function test_clock_matchesTokenClock() public view {
        assertEq(uint256(governor.clock()), uint256(token.clock()));
    }

    function test_timelockMinDelay() public view {
        assertEq(timelock.getMinDelay(), MIN_DELAY);
    }

    // ============================================================
    // TIMELOCK ROLES
    // ============================================================

    function test_governorHasProposerRole() public view {
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)));
    }

    function test_governorHasCancellerRole() public view {
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), address(governor)));
    }

    function test_executorRoleIsOpen() public view {
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)));
    }

    function test_attackerDoesNotHaveProposerRole() public view {
        assertFalse(timelock.hasRole(timelock.PROPOSER_ROLE(), attacker));
    }

    // ============================================================
    // QUORUM
    // ============================================================

    function test_quorumIsFourPercent() public {
        uint256 snapshot = vm.getBlockNumber();

        vm.roll(snapshot + 1);

        assertEq(governor.quorum(snapshot), QUORUM);
    }

    function test_quorumTracksPastTotalSupply() public {
        uint256 snapshot = vm.getBlockNumber();

        vm.roll(snapshot + 1);

        uint256 supply = token.getPastTotalSupply(snapshot);

        assertEq(governor.quorum(snapshot), supply * 4 / 100);
    }

    function test_quorum_revertsCurrentBlock() public {
        vm.expectRevert();

        governor.quorum(vm.getBlockNumber());
    }

    // ============================================================
    // PROPOSAL CREATION
    // ============================================================

    function test_propose_success() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(123, "proposal-one");

        uint256 expected = governor.hashProposal(targets, values, calldatas, descriptionHash);

        assertEq(proposalId, expected);

        assertEq(governor.proposalProposer(proposalId), address(this));

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));
    }

    function test_proposalNeedsQueuing() public {
        (uint256 proposalId,,,,) = _createProposal(123, "needs-queue");

        assertTrue(governor.proposalNeedsQueuing(proposalId));
    }

    function test_proposalSnapshotCorrect() public {
        uint256 start = vm.getBlockNumber();

        (uint256 proposalId,,,,) = _createProposal(1, "snapshot");

        assertEq(governor.proposalSnapshot(proposalId), start + VOTING_DELAY);
    }

    function test_proposalDeadlineCorrect() public {
        (uint256 proposalId,,,,) = _createProposal(1, "deadline");

        uint256 snapshot = governor.proposalSnapshot(proposalId);

        assertEq(governor.proposalDeadline(proposalId), snapshot + VOTING_PERIOD);
    }

    function test_sameProposalDataProducesSameHash() public view {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposalData(999);

        bytes32 descriptionHash = keccak256(bytes("same-proposal"));

        uint256 first = governor.hashProposal(targets, values, calldatas, descriptionHash);

        uint256 second = governor.hashProposal(targets, values, calldatas, descriptionHash);

        assertEq(first, second);
    }

    function test_differentDescriptionChangesProposalId() public view {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposalData(999);

        uint256 first = governor.hashProposal(targets, values, calldatas, keccak256(bytes("A")));

        uint256 second = governor.hashProposal(targets, values, calldatas, keccak256(bytes("B")));

        assertTrue(first != second);
    }

    function test_propose_revertsEmptyProposal() public {
        address[] memory targets = new address[](0);

        uint256[] memory values = new uint256[](0);

        bytes[] memory calldatas = new bytes[](0);

        vm.expectRevert();

        governor.propose(targets, values, calldatas, "empty");
    }

    function test_propose_revertsMismatchedLengths() public {
        address[] memory targets = new address[](1);

        uint256[] memory values = new uint256[](0);

        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(target);

        calldatas[0] = abi.encodeCall(GovernorTarget.setValue, (123));

        vm.expectRevert();

        governor.propose(targets, values, calldatas, "bad-length");
    }

    // ============================================================
    // PENDING / ACTIVE
    // ============================================================

    function test_state_pendingImmediatelyAfterProposal() public {
        (uint256 proposalId,,,,) = _createProposal(123, "pending");

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));
    }

    function test_state_activeAfterVotingDelay() public {
        (uint256 proposalId,,,,) = _createProposal(123, "active");

        _activateProposal(proposalId);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));
    }

    // ============================================================
    // VOTING
    // ============================================================

    function test_castVoteFor() public {
        (uint256 proposalId,,,,) = _createProposal(123, "vote-for");

        _activateProposal(proposalId);

        uint256 weight = governor.castVote(proposalId, 1);

        assertEq(weight, INITIAL_SUPPLY);

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);

        assertEq(againstVotes, 0);

        assertEq(forVotes, INITIAL_SUPPLY);

        assertEq(abstainVotes, 0);

        assertTrue(governor.hasVoted(proposalId, address(this)));
    }

    function test_castVoteAgainst() public {
        (uint256 proposalId,,,,) = _createProposal(123, "vote-against");

        _activateProposal(proposalId);

        governor.castVote(proposalId, 0);

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);

        assertEq(againstVotes, INITIAL_SUPPLY);

        assertEq(forVotes, 0);

        assertEq(abstainVotes, 0);
    }

    function test_castVoteAbstain() public {
        (uint256 proposalId,,,,) = _createProposal(123, "vote-abstain");

        _activateProposal(proposalId);

        governor.castVote(proposalId, 2);

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);

        assertEq(againstVotes, 0);

        assertEq(forVotes, 0);

        assertEq(abstainVotes, INITIAL_SUPPLY);
    }

    function test_castVoteWithReason() public {
        (uint256 proposalId,,,,) = _createProposal(123, "reason");

        _activateProposal(proposalId);

        uint256 weight = governor.castVoteWithReason(proposalId, 1, "I support this");

        assertEq(weight, INITIAL_SUPPLY);
    }

    function test_doubleVoteReverts() public {
        (uint256 proposalId,,,,) = _createProposal(123, "double-vote");

        _activateProposal(proposalId);

        governor.castVote(proposalId, 1);

        vm.expectRevert();

        governor.castVote(proposalId, 1);
    }

    function test_invalidVoteTypeReverts() public {
        (uint256 proposalId,,,,) = _createProposal(123, "invalid-vote");

        _activateProposal(proposalId);

        vm.expectRevert();

        governor.castVote(proposalId, 3);
    }

    function test_voteBeforeActiveReverts() public {
        (uint256 proposalId,,,,) = _createProposal(123, "early-vote");

        vm.expectRevert();

        governor.castVote(proposalId, 1);
    }

    function test_voteAfterDeadlineReverts() public {
        (uint256 proposalId,,,,) = _createProposal(123, "late-vote");

        _activateProposal(proposalId);

        uint256 deadline = governor.proposalDeadline(proposalId);

        vm.roll(deadline + 1);

        vm.expectRevert();

        governor.castVote(proposalId, 1);
    }

    // ============================================================
    // SUCCEEDED / DEFEATED
    // ============================================================

    function test_proposalSucceedsWithForVotes() public {
        (uint256 proposalId,,,,) = _createProposal(123, "success");

        _activateProposal(proposalId);

        governor.castVote(proposalId, 1);

        _finishVoting(proposalId);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));
    }

    function test_proposalDefeatedWithAgainstVotes() public {
        (uint256 proposalId,,,,) = _createProposal(123, "defeat-against");

        _activateProposal(proposalId);

        governor.castVote(proposalId, 0);

        _finishVoting(proposalId);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_abstainOnlyProposalIsDefeated() public {
        (uint256 proposalId,,,,) = _createProposal(123, "abstain-only");

        _activateProposal(proposalId);

        governor.castVote(proposalId, 2);

        _finishVoting(proposalId);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_proposalDefeatedWithoutQuorum() public {
        /*
         * Reduce this account's delegated votes to 10,000.
         * Total supply stays at 1,000,000, so quorum remains 40,000.
         */
        token.transfer(voter2, 990_000 ether);

        assertEq(token.getVotes(address(this)), 10_000 ether);

        (uint256 proposalId,,,,) = _createProposal(123, "no-quorum");

        _activateProposal(proposalId);

        governor.castVote(proposalId, 1);

        _finishVoting(proposalId);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated));
    }

    // ============================================================
    // QUEUE
    // ============================================================

    function test_queueSuccessfulProposal() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(555, "queue-success");

        _passProposal(proposalId);

        uint256 eta = governor.queue(targets, values, calldatas, descriptionHash);

        assertGt(eta, vm.getBlockTimestamp());

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));
    }

    function test_queueBeforeProposalSucceedsReverts() public {
        (, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash) =
            _createProposal(555, "queue-early");

        vm.expectRevert();

        governor.queue(targets, values, calldatas, descriptionHash);
    }

    function test_queueDefeatedProposalReverts() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(555, "queue-defeated");

        _activateProposal(proposalId);

        governor.castVote(proposalId, 0);

        _finishVoting(proposalId);

        vm.expectRevert();

        governor.queue(targets, values, calldatas, descriptionHash);
    }

    // ============================================================
    // EXECUTION
    // ============================================================

    function test_executeSuccessfulProposal() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(777, "execute-success");

        _passProposal(proposalId);

        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(vm.getBlockTimestamp() + MIN_DELAY);

        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(target.value(), 777);

        assertEq(target.lastCaller(), address(timelock));

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));
    }

    function test_executeBeforeTimelockDelayReverts() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(888, "execute-early");

        _passProposal(proposalId);

        governor.queue(targets, values, calldatas, descriptionHash);

        vm.expectRevert();

        governor.execute(targets, values, calldatas, descriptionHash);
    }

    function test_executeWithoutQueueReverts() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(999, "execute-no-queue");

        _passProposal(proposalId);

        vm.expectRevert();

        governor.execute(targets, values, calldatas, descriptionHash);
    }

    function test_executeReplayReverts() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(111, "execute-replay");

        _passProposal(proposalId);

        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(vm.getBlockTimestamp() + MIN_DELAY);

        governor.execute(targets, values, calldatas, descriptionHash);

        vm.expectRevert();

        governor.execute(targets, values, calldatas, descriptionHash);
    }

    function test_anyoneCanExecuteReadyProposal() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(222, "permissionless-execute");

        _passProposal(proposalId);

        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(vm.getBlockTimestamp() + MIN_DELAY);

        vm.prank(attacker);

        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(target.value(), 222);

        assertEq(target.lastCaller(), address(timelock));
    }

    function test_targetRevertCausesExecutionRevert() public {
        address[] memory targets = new address[](1);

        uint256[] memory values = new uint256[](1);

        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(target);

        calldatas[0] = abi.encodeCall(GovernorTarget.revertingCall, ());

        string memory description = "reverting-target";

        bytes32 descriptionHash = keccak256(bytes(description));

        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        _passProposal(proposalId);

        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(vm.getBlockTimestamp() + MIN_DELAY);

        vm.expectRevert();

        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));
    }

    // ============================================================
    // CANCELLATION
    // ============================================================

    function test_proposerCanCancelPendingProposal() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(321, "cancel-pending");

        governor.cancel(targets, values, calldatas, descriptionHash);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Canceled));
    }

    function test_attackerCannotCancelProposal() public {
        (, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash) =
            _createProposal(321, "attacker-cancel");

        vm.prank(attacker);

        vm.expectRevert();

        governor.cancel(targets, values, calldatas, descriptionHash);
    }

    function test_proposerCannotCancelAfterProposalActive() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(321, "late-cancel");

        _activateProposal(proposalId);

        vm.expectRevert();

        governor.cancel(targets, values, calldatas, descriptionHash);
    }

    function test_canceledProposalCannotBeVoted() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(321, "cancel-no-vote");

        governor.cancel(targets, values, calldatas, descriptionHash);

        vm.roll(governor.proposalSnapshot(proposalId) + 1);

        vm.expectRevert();

        governor.castVote(proposalId, 1);
    }

    // ============================================================
    // SNAPSHOT SECURITY
    // ============================================================

    function test_votesUseSnapshotNotCurrentBalance() public {
        (uint256 proposalId,,,,) = _createProposal(1, "snapshot-security");

        uint256 snapshot = governor.proposalSnapshot(proposalId);

        /*
        * Move to the first ACTIVE block.
        *
        * At this point snapshot is already strictly in the past.
        */
        vm.roll(snapshot + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));

        /*
        * Transfer AFTER the snapshot.
        * Current voting power changes, historical snapshot power must not.
        */
        token.transfer(voter2, 900_000 ether);

        assertEq(token.getVotes(address(this)), 100_000 ether);

        /*
        * Governor must still use voting power at proposal snapshot.
        */
        uint256 weight = governor.castVote(proposalId, 1);

        assertEq(weight, INITIAL_SUPPLY);

        (, uint256 forVotes,) = governor.proposalVotes(proposalId);

        assertEq(forVotes, INITIAL_SUPPLY);
    }

    function test_tokensTransferredBeforeSnapshotReduceVotes() public {
        token.transfer(voter2, 900_000 ether);

        (uint256 proposalId,,,,) = _createProposal(1, "pre-snapshot-transfer");

        _activateProposal(proposalId);

        uint256 weight = governor.castVote(proposalId, 1);

        assertEq(weight, 100_000 ether);
    }

    // ============================================================
    // FUZZ
    // ============================================================

    function testFuzz_hashProposalDeterministic(uint256 newValue, bytes32 salt) public view {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposalData(newValue);

        bytes32 first = bytes32(governor.hashProposal(targets, values, calldatas, salt));

        bytes32 second = bytes32(governor.hashProposal(targets, values, calldatas, salt));

        assertEq(first, second);
    }

    function testFuzz_successfulProposalExecutesValue(uint96 rawValue) public {
        uint256 newValue = uint256(rawValue);

        string memory description = string(abi.encodePacked("fuzz-execute-", vm.toString(newValue)));

        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _createProposal(newValue, description);

        _passProposal(proposalId);

        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(vm.getBlockTimestamp() + MIN_DELAY);

        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(target.value(), newValue);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));
    }

    function testFuzz_forVoteWeightMatchesSnapshot(uint96 rawTransfer) public {
        uint256 transferAmount = bound(uint256(rawTransfer), 0, INITIAL_SUPPLY - QUORUM);

        token.transfer(voter2, transferAmount);

        uint256 expectedVotes = INITIAL_SUPPLY - transferAmount;

        (uint256 proposalId,,,,) = _createProposal(1, "fuzz-vote-weight");

        _activateProposal(proposalId);

        uint256 weight = governor.castVote(proposalId, 1);

        assertEq(weight, expectedVotes);
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _proposalData(uint256 newValue)
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](1);

        values = new uint256[](1);

        calldatas = new bytes[](1);

        targets[0] = address(target);

        values[0] = 0;

        calldatas[0] = abi.encodeCall(GovernorTarget.setValue, (newValue));
    }

    function _createProposal(uint256 newValue, string memory description)
        internal
        returns (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        )
    {
        (targets, values, calldatas) = _proposalData(newValue);

        descriptionHash = keccak256(bytes(description));

        proposalId = governor.propose(targets, values, calldatas, description);
    }

    function _activateProposal(uint256 proposalId) internal {
        uint256 snapshot = governor.proposalSnapshot(proposalId);

        vm.roll(snapshot + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));
    }

    function _finishVoting(uint256 proposalId) internal {
        uint256 deadline = governor.proposalDeadline(proposalId);

        vm.roll(deadline + 1);
    }

    function _passProposal(uint256 proposalId) internal {
        _activateProposal(proposalId);

        governor.castVote(proposalId, 1);

        _finishVoting(proposalId);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));
    }
}
