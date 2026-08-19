// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {TokenVesting} from "../src/contracts/token/TokenVesting.sol";

import {MockERC20} from "../src/contracts/test/MockERC20.sol";

import {NoReturnERC20} from "../src/contracts/test/NoReturnERC20.sol";

import {FalseReturnERC20} from "../src/contracts/test/FalseReturnERC20.sol";

contract RevertingVestingToken {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert("TRANSFER_REVERT");
    }
}

contract ToggleVestingToken {
    mapping(address => uint256) public balanceOf;

    bool public failTransfer;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function setFailTransfer(bool value) external {
        failTransfer = value;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        if (failTransfer) {
            return false;
        }

        require(balanceOf[msg.sender] >= amount, "BALANCE_LOW");

        balanceOf[msg.sender] -= amount;

        balanceOf[to] += amount;

        return true;
    }
}

contract TokenVestingFinalSecurityTest is Test {
    TokenVesting internal vesting;
    MockERC20 internal token;

    address internal beneficiary;
    address internal attacker;

    uint256 internal constant TOTAL = 1_000 ether;

    uint256 internal constant DURATION = 365 days;

    uint256 internal constant CLIFF = 30 days;

    uint256 internal start;

    function setUp() public {
        beneficiary = makeAddr("beneficiary");

        attacker = makeAddr("attacker");

        token = new MockERC20("Mock Token", "MOCK");

        start = block.timestamp;

        vesting = new TokenVesting(address(token), beneficiary, start, CLIFF, DURATION, TOTAL);

        token.mint(address(vesting), TOTAL);
    }

    // =============================================================
    // CONSTRUCTOR
    // =============================================================

    function test_constructor_setsState() public view {
        assertEq(address(vesting.token()), address(token));

        assertEq(vesting.beneficiary(), beneficiary);

        assertEq(vesting.start(), start);

        assertEq(vesting.cliff(), start + CLIFF);

        assertEq(vesting.duration(), DURATION);

        assertEq(vesting.end(), start + DURATION);

        assertEq(vesting.totalAmount(), TOTAL);

        assertEq(vesting.released(), 0);
    }

    function test_constructor_revertsZeroToken() public {
        vm.expectRevert(TokenVesting.ZeroToken.selector);

        new TokenVesting(address(0), beneficiary, start, CLIFF, DURATION, TOTAL);
    }

    function test_constructor_revertsZeroBeneficiary() public {
        vm.expectRevert(TokenVesting.ZeroBeneficiary.selector);

        new TokenVesting(address(token), address(0), start, CLIFF, DURATION, TOTAL);
    }

    function test_constructor_revertsZeroAmount() public {
        vm.expectRevert(TokenVesting.ZeroAmount.selector);

        new TokenVesting(address(token), beneficiary, start, CLIFF, DURATION, 0);
    }

    function test_constructor_revertsZeroDuration() public {
        vm.expectRevert(TokenVesting.ZeroDuration.selector);

        new TokenVesting(address(token), beneficiary, start, 0, 0, TOTAL);
    }

    function test_constructor_revertsCliffGreaterThanDuration() public {
        vm.expectRevert(TokenVesting.InvalidCliff.selector);

        new TokenVesting(address(token), beneficiary, start, DURATION + 1, DURATION, TOTAL);
    }

    function test_constructor_allowsCliffEqualDuration() public {
        TokenVesting local = new TokenVesting(address(token), beneficiary, start, DURATION, DURATION, TOTAL);

        assertEq(local.cliff(), start + DURATION);

        assertEq(local.end(), start + DURATION);
    }

    function test_constructor_revertsTimestampOverflow() public {
        vm.expectRevert(TokenVesting.TimestampOverflow.selector);

        new TokenVesting(address(token), beneficiary, type(uint256).max - DURATION + 1, 0, DURATION, TOTAL);
    }

    // =============================================================
    // VESTED AMOUNT
    // =============================================================

    function test_vestedAmount_beforeStartIsZero() public view {
        assertEq(vesting.vestedAmount(start - 1), 0);
    }

    function test_vestedAmount_beforeCliffIsZero() public view {
        assertEq(vesting.vestedAmount(start + CLIFF - 1), 0);
    }

    function test_vestedAmount_atExactCliff() public view {
        uint256 expected = TOTAL * CLIFF / DURATION;

        assertEq(vesting.vestedAmount(start + CLIFF), expected);
    }

    function test_vestedAmount_halfDuration() public view {
        uint256 timestamp = start + DURATION / 2;

        uint256 expected = TOTAL * (timestamp - start) / DURATION;

        assertEq(vesting.vestedAmount(timestamp), expected);
    }

    function test_vestedAmount_exactEnd() public view {
        assertEq(vesting.vestedAmount(start + DURATION), TOTAL);
    }

    function test_vestedAmount_afterEndCappedAtTotal() public view {
        assertEq(vesting.vestedAmount(start + DURATION + 1000 days), TOTAL);
    }

    // =============================================================
    // RELEASABLE
    // =============================================================

    function test_releasable_beforeCliffIsZero() public {
        vm.warp(start + CLIFF - 1);

        assertEq(vesting.releasableAmount(), 0);
    }

    function test_releasable_atCliffMatchesVested() public {
        vm.warp(start + CLIFF);

        uint256 expected = TOTAL * CLIFF / DURATION;

        assertEq(vesting.releasableAmount(), expected);
    }

    function test_releasable_afterPartialReleaseSubtractsReleased() public {
        vm.warp(start + 90 days);

        vm.prank(beneficiary);

        vesting.release();

        uint256 firstReleased = vesting.released();

        vm.warp(start + 180 days);

        uint256 vestedNow = vesting.vestedAmount(block.timestamp);

        assertEq(vesting.releasableAmount(), vestedNow - firstReleased);
    }

    // =============================================================
    // RELEASE
    // =============================================================

    function test_release_revertsNonBeneficiary() public {
        vm.warp(start + 90 days);

        vm.prank(attacker);

        vm.expectRevert(TokenVesting.NotBeneficiary.selector);

        vesting.release();
    }

    function test_release_revertsNothingAvailableBeforeCliff() public {
        vm.warp(start + CLIFF - 1);

        vm.prank(beneficiary);

        vm.expectRevert(TokenVesting.NothingToRelease.selector);

        vesting.release();
    }

    function test_release_successAtCliff() public {
        vm.warp(start + CLIFF);

        uint256 expected = vesting.vestedAmount(block.timestamp);

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), expected);

        assertEq(token.balanceOf(beneficiary), expected);

        assertEq(vesting.releasableAmount(), 0);
    }

    function test_release_emitsEvent() public {
        vm.warp(start + 90 days);

        uint256 expected = vesting.vestedAmount(block.timestamp);

        vm.expectEmit(true, false, false, true);

        emit TokenVesting.TokensReleased(beneficiary, expected);

        vm.prank(beneficiary);

        vesting.release();
    }

    function test_release_multiplePartialClaims() public {
        vm.warp(start + 90 days);

        uint256 vestedAt90 = vesting.vestedAmount(block.timestamp);

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), vestedAt90);

        assertEq(token.balanceOf(beneficiary), vestedAt90);

        vm.warp(start + 180 days);

        uint256 vestedAt180 = vesting.vestedAmount(block.timestamp);

        uint256 secondClaim = vestedAt180 - vestedAt90;

        assertEq(vesting.releasableAmount(), secondClaim);

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), vestedAt180);

        assertEq(token.balanceOf(beneficiary), vestedAt180);

        assertEq(vesting.releasableAmount(), 0);
    }

    function test_release_fullAmountAtEnd() public {
        vm.warp(start + DURATION);

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), TOTAL);

        assertEq(token.balanceOf(beneficiary), TOTAL);

        assertEq(token.balanceOf(address(vesting)), 0);
    }

    function test_release_afterFullReleaseReverts() public {
        vm.warp(start + DURATION);

        vm.prank(beneficiary);

        vesting.release();

        vm.prank(beneficiary);

        vm.expectRevert(TokenVesting.NothingToRelease.selector);

        vesting.release();
    }

    function test_release_exactEndTimestamp() public {
        vm.warp(vesting.end());

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), TOTAL);
    }

    function test_release_afterEndStillOnlyReleasesTotal() public {
        vm.warp(vesting.end() + 1000 days);

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), TOTAL);
    }

    // =============================================================
    // SAFE ERC20 TOKEN BEHAVIOR
    // =============================================================

    function test_release_acceptsNoReturnToken() public {
        NoReturnERC20 noReturnToken = new NoReturnERC20();

        TokenVesting local = new TokenVesting(address(noReturnToken), beneficiary, start, 0, DURATION, TOTAL);

        noReturnToken.mint(address(local), TOTAL);

        vm.warp(start + DURATION);

        vm.prank(beneficiary);

        local.release();

        assertEq(noReturnToken.balanceOf(beneficiary), TOTAL);

        assertEq(local.released(), TOTAL);
    }

    function test_release_falseReturnTokenRevertsAndStateRollsBack() public {
        FalseReturnERC20 falseToken = new FalseReturnERC20();

        TokenVesting local = new TokenVesting(address(falseToken), beneficiary, start, 0, DURATION, TOTAL);

        falseToken.mint(address(local), TOTAL);

        vm.warp(start + DURATION);

        vm.prank(beneficiary);

        vm.expectRevert();

        local.release();

        assertEq(local.released(), 0);
    }

    function test_release_revertingTokenRollsBackReleased() public {
        RevertingVestingToken badToken = new RevertingVestingToken();

        TokenVesting local = new TokenVesting(address(badToken), beneficiary, start, 0, DURATION, TOTAL);

        badToken.mint(address(local), TOTAL);

        vm.warp(start + DURATION);

        vm.prank(beneficiary);

        vm.expectRevert();

        local.release();

        assertEq(local.released(), 0);

        assertEq(badToken.balanceOf(address(local)), TOTAL);
    }

    function test_failedTransferDoesNotCorruptReleaseAccounting() public {
        ToggleVestingToken toggleToken = new ToggleVestingToken();

        TokenVesting local = new TokenVesting(address(toggleToken), beneficiary, start, 0, DURATION, TOTAL);

        toggleToken.mint(address(local), TOTAL);

        toggleToken.setFailTransfer(true);

        vm.warp(start + DURATION);

        vm.prank(beneficiary);

        vm.expectRevert();

        local.release();

        assertEq(local.released(), 0);

        toggleToken.setFailTransfer(false);

        vm.prank(beneficiary);

        local.release();

        assertEq(local.released(), TOTAL);

        assertEq(toggleToken.balanceOf(beneficiary), TOTAL);
    }

    // =============================================================
    // FUNDING EDGE CASES
    // =============================================================

    function test_release_revertsIfContractUnderfunded() public {
        TokenVesting local = new TokenVesting(address(token), beneficiary, start, 0, DURATION, TOTAL);

        token.mint(address(local), TOTAL - 1);

        vm.warp(start + DURATION);

        vm.prank(beneficiary);

        vm.expectRevert();

        local.release();

        assertEq(local.released(), 0);
    }

    function test_extraFundingDoesNotIncreaseTotalVesting() public {
        token.mint(address(vesting), 500 ether);

        vm.warp(start + DURATION);

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), TOTAL);

        assertEq(token.balanceOf(beneficiary), TOTAL);

        assertEq(token.balanceOf(address(vesting)), 500 ether);
    }

    // =============================================================
    // FUZZ
    // =============================================================

    function testFuzz_vestedAmountNeverExceedsTotal(uint256 timestamp) public view {
        uint256 vested = vesting.vestedAmount(timestamp);

        assertLe(vested, TOTAL);
    }

    function testFuzz_linearVestingMatchesFormula(uint32 rawElapsed) public view {
        uint256 elapsed = bound(uint256(rawElapsed), CLIFF, DURATION - 1);

        uint256 timestamp = start + elapsed;

        uint256 expected = TOTAL * elapsed / DURATION;

        assertEq(vesting.vestedAmount(timestamp), expected);
    }

    function testFuzz_releaseAccounting(uint32 rawElapsed) public {
        uint256 elapsed = bound(uint256(rawElapsed), CLIFF, DURATION);

        vm.warp(start + elapsed);

        uint256 expected = vesting.vestedAmount(block.timestamp);

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), expected);

        assertEq(token.balanceOf(beneficiary), expected);

        assertLe(vesting.released(), vesting.totalAmount());
    }

    function testFuzz_twoStageReleaseAccounting(uint32 rawFirst, uint32 rawSecond) public {
        uint256 firstElapsed = bound(uint256(rawFirst), CLIFF, DURATION - 1);

        uint256 secondElapsed = bound(uint256(rawSecond), firstElapsed + 1, DURATION);

        vm.warp(start + firstElapsed);

        uint256 vestedFirst = vesting.vestedAmount(block.timestamp);

        vm.prank(beneficiary);

        vesting.release();

        vm.warp(start + secondElapsed);

        uint256 vestedSecond = vesting.vestedAmount(block.timestamp);

        vm.prank(beneficiary);

        vesting.release();

        assertEq(vesting.released(), vestedSecond);

        assertEq(token.balanceOf(beneficiary), vestedSecond);

        assertGe(vestedSecond, vestedFirst);
    }
}
