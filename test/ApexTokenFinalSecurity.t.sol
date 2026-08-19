// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {
    ApexToken
} from "../src/contracts/token/ApexToken.sol";

import {
    IERC20Errors
} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {
    Ownable
} from "@openzeppelin/contracts/access/Ownable.sol";

import {
    Pausable
} from "@openzeppelin/contracts/utils/Pausable.sol";

import {
    ERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";


contract ApexTokenFinalSecurityTest is Test {

    ApexToken internal token;


    address internal liquidity;
    address internal community;
    address internal treasury;
    address internal team;
    address internal marketing;
    address internal reserve;

    address internal alice;
    address internal bob;
    address internal attacker;


    uint256 internal constant LIQUIDITY_ALLOCATION =
        200_000_000 ether;

    uint256 internal constant COMMUNITY_ALLOCATION =
        250_000_000 ether;

    uint256 internal constant TREASURY_ALLOCATION =
        200_000_000 ether;

    uint256 internal constant TEAM_ALLOCATION =
        150_000_000 ether;

    uint256 internal constant MARKETING_ALLOCATION =
        100_000_000 ether;

    uint256 internal constant RESERVE_ALLOCATION =
        100_000_000 ether;

    uint256 internal constant MAX_SUPPLY =
        1_000_000_000 ether;


    uint256 internal constant PERMIT_OWNER_PK =
        0xA11CE;

    uint256 internal constant WRONG_SIGNER_PK =
        0xB0B;


    // =============================================================
    // SETUP
    // =============================================================

    function setUp()
        public
    {
        liquidity =
            makeAddr("liquidity");

        community =
            makeAddr("community");

        treasury =
            makeAddr("treasury");

        team =
            makeAddr("team");

        marketing =
            makeAddr("marketing");

        reserve =
            makeAddr("reserve");

        alice =
            makeAddr("alice");

        bob =
            makeAddr("bob");

        attacker =
            makeAddr("attacker");


        token =
            new ApexToken(
                liquidity,
                community,
                treasury,
                team,
                marketing,
                reserve
            );
    }


    // =============================================================
    // CONSTRUCTOR / METADATA
    // =============================================================

    function test_constructor_metadata()
        public
        view
    {
        assertEq(
            token.name(),
            "Apex Token"
        );

        assertEq(
            token.symbol(),
            "APEX"
        );

        assertEq(
            token.decimals(),
            18
        );
    }


    function test_constructor_ownerIsDeployer()
        public
        view
    {
        assertEq(
            token.owner(),
            address(this)
        );

        assertEq(
            token.pendingOwner(),
            address(0)
        );
    }


    function test_constructor_initiallyUnpaused()
        public
        view
    {
        assertFalse(
            token.paused()
        );
    }


    function test_constructor_totalSupplyEqualsMaxSupply()
        public
        view
    {
        assertEq(
            token.totalSupply(),
            MAX_SUPPLY
        );

        assertEq(
            token.totalSupply(),
            token.MAX_SUPPLY()
        );
    }


    function test_constructor_constantsCorrect()
        public
        view
    {
        assertEq(
            token.LIQUIDITY_ALLOCATION(),
            LIQUIDITY_ALLOCATION
        );

        assertEq(
            token.COMMUNITY_ALLOCATION(),
            COMMUNITY_ALLOCATION
        );

        assertEq(
            token.TREASURY_ALLOCATION(),
            TREASURY_ALLOCATION
        );

        assertEq(
            token.TEAM_ALLOCATION(),
            TEAM_ALLOCATION
        );

        assertEq(
            token.MARKETING_ALLOCATION(),
            MARKETING_ALLOCATION
        );

        assertEq(
            token.RESERVE_ALLOCATION(),
            RESERVE_ALLOCATION
        );
    }


    function test_constructor_allocationSumEqualsMaxSupply()
        public
        view
    {
        uint256 total =
            token.LIQUIDITY_ALLOCATION()
            +
            token.COMMUNITY_ALLOCATION()
            +
            token.TREASURY_ALLOCATION()
            +
            token.TEAM_ALLOCATION()
            +
            token.MARKETING_ALLOCATION()
            +
            token.RESERVE_ALLOCATION();

        assertEq(
            total,
            token.MAX_SUPPLY()
        );
    }


    function test_constructor_balancesCorrect()
        public
        view
    {
        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION
        );

        assertEq(
            token.balanceOf(community),
            COMMUNITY_ALLOCATION
        );

        assertEq(
            token.balanceOf(treasury),
            TREASURY_ALLOCATION
        );

        assertEq(
            token.balanceOf(team),
            TEAM_ALLOCATION
        );

        assertEq(
            token.balanceOf(marketing),
            MARKETING_ALLOCATION
        );

        assertEq(
            token.balanceOf(reserve),
            RESERVE_ALLOCATION
        );
    }


    function test_constructor_allBalancesEqualTotalSupply()
        public
        view
    {
        uint256 total =
            token.balanceOf(liquidity)
            +
            token.balanceOf(community)
            +
            token.balanceOf(treasury)
            +
            token.balanceOf(team)
            +
            token.balanceOf(marketing)
            +
            token.balanceOf(reserve);

        assertEq(
            total,
            token.totalSupply()
        );
    }


    function test_constructor_revertsZeroLiquidity()
        public
    {
        vm.expectRevert(
            ApexToken.ZeroAddress.selector
        );

        new ApexToken(
            address(0),
            community,
            treasury,
            team,
            marketing,
            reserve
        );
    }


    function test_constructor_revertsZeroCommunity()
        public
    {
        vm.expectRevert(
            ApexToken.ZeroAddress.selector
        );

        new ApexToken(
            liquidity,
            address(0),
            treasury,
            team,
            marketing,
            reserve
        );
    }


    function test_constructor_revertsZeroTreasury()
        public
    {
        vm.expectRevert(
            ApexToken.ZeroAddress.selector
        );

        new ApexToken(
            liquidity,
            community,
            address(0),
            team,
            marketing,
            reserve
        );
    }


    function test_constructor_revertsZeroTeam()
        public
    {
        vm.expectRevert(
            ApexToken.ZeroAddress.selector
        );

        new ApexToken(
            liquidity,
            community,
            treasury,
            address(0),
            marketing,
            reserve
        );
    }


    function test_constructor_revertsZeroMarketing()
        public
    {
        vm.expectRevert(
            ApexToken.ZeroAddress.selector
        );

        new ApexToken(
            liquidity,
            community,
            treasury,
            team,
            address(0),
            reserve
        );
    }


    function test_constructor_revertsZeroReserve()
        public
    {
        vm.expectRevert(
            ApexToken.ZeroAddress.selector
        );

        new ApexToken(
            liquidity,
            community,
            treasury,
            team,
            marketing,
            address(0)
        );
    }


    // =============================================================
    // ERC20 TRANSFER
    // =============================================================

    function test_transfer_success()
        public
    {
        uint256 amount =
            100 ether;

        vm.prank(liquidity);

        bool success =
            token.transfer(
                alice,
                amount
            );

        assertTrue(
            success
        );

        assertEq(
            token.balanceOf(alice),
            amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertEq(
            token.totalSupply(),
            MAX_SUPPLY
        );
    }


    function test_transfer_exactBalance()
        public
    {
        vm.prank(liquidity);

        token.transfer(
            alice,
            LIQUIDITY_ALLOCATION
        );

        assertEq(
            token.balanceOf(liquidity),
            0
        );

        assertEq(
            token.balanceOf(alice),
            LIQUIDITY_ALLOCATION
        );
    }


    function test_transfer_zeroAmount()
        public
    {
        uint256 senderBefore =
            token.balanceOf(
                liquidity
            );

        uint256 receiverBefore =
            token.balanceOf(
                alice
            );

        vm.prank(liquidity);

        bool success =
            token.transfer(
                alice,
                0
            );

        assertTrue(
            success
        );

        assertEq(
            token.balanceOf(liquidity),
            senderBefore
        );

        assertEq(
            token.balanceOf(alice),
            receiverBefore
        );
    }


    function test_transfer_toSelf()
        public
    {
        uint256 beforeBalance =
            token.balanceOf(
                liquidity
            );

        vm.prank(liquidity);

        token.transfer(
            liquidity,
            100 ether
        );

        assertEq(
            token.balanceOf(liquidity),
            beforeBalance
        );
    }


    function test_transfer_revertsZeroRecipient()
        public
    {
        vm.prank(liquidity);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors
                    .ERC20InvalidReceiver
                    .selector,
                address(0)
            )
        );

        token.transfer(
            address(0),
            1 ether
        );
    }


    function test_transfer_revertsInsufficientBalance()
        public
    {
        uint256 balance =
            token.balanceOf(
                liquidity
            );

        vm.prank(liquidity);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors
                    .ERC20InsufficientBalance
                    .selector,
                liquidity,
                balance,
                balance + 1
            )
        );

        token.transfer(
            alice,
            balance + 1
        );
    }


    function test_transfer_doesNotAffectOtherAccounts()
        public
    {
        uint256 communityBefore =
            token.balanceOf(
                community
            );

        uint256 treasuryBefore =
            token.balanceOf(
                treasury
            );

        vm.prank(liquidity);

        token.transfer(
            alice,
            100 ether
        );

        assertEq(
            token.balanceOf(community),
            communityBefore
        );

        assertEq(
            token.balanceOf(treasury),
            treasuryBefore
        );
    }


    // =============================================================
    // APPROVAL / TRANSFERFROM
    // =============================================================

    function test_approve_success()
        public
    {
        vm.prank(liquidity);

        bool success =
            token.approve(
                alice,
                100 ether
            );

        assertTrue(
            success
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            100 ether
        );
    }


    function test_approve_canUpdateAllowance()
        public
    {
        vm.startPrank(liquidity);

        token.approve(
            alice,
            100 ether
        );

        token.approve(
            alice,
            200 ether
        );

        vm.stopPrank();

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            200 ether
        );
    }


    function test_approve_zeroAmount()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            0
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            0
        );
    }


    function test_transferFrom_success()
        public
    {
        uint256 amount =
            100 ether;

        vm.prank(liquidity);

        token.approve(
            alice,
            amount
        );

        vm.prank(alice);

        bool success =
            token.transferFrom(
                liquidity,
                bob,
                amount
            );

        assertTrue(
            success
        );

        assertEq(
            token.balanceOf(bob),
            amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            0
        );
    }


    function test_transferFrom_consumesFiniteAllowance()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            300 ether
        );

        vm.prank(alice);

        token.transferFrom(
            liquidity,
            bob,
            100 ether
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            200 ether
        );
    }


    function test_transferFrom_maxAllowanceDoesNotDecrease()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            type(uint256).max
        );

        vm.prank(alice);

        token.transferFrom(
            liquidity,
            bob,
            100 ether
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            type(uint256).max
        );
    }


    function test_transferFrom_zeroAmount()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            100 ether
        );

        vm.prank(alice);

        bool success =
            token.transferFrom(
                liquidity,
                bob,
                0
            );

        assertTrue(
            success
        );

        assertEq(
            token.balanceOf(bob),
            0
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            100 ether
        );
    }


    function test_transferFrom_revertsInsufficientAllowance()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            50 ether
        );

        vm.prank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors
                    .ERC20InsufficientAllowance
                    .selector,
                alice,
                50 ether,
                100 ether
            )
        );

        token.transferFrom(
            liquidity,
            bob,
            100 ether
        );
    }


    function test_transferFrom_revertsInsufficientBalance()
        public
    {
        uint256 amount =
            LIQUIDITY_ALLOCATION + 1;

        vm.prank(liquidity);

        token.approve(
            alice,
            amount
        );

        vm.prank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors
                    .ERC20InsufficientBalance
                    .selector,
                liquidity,
                LIQUIDITY_ALLOCATION,
                amount
            )
        );

        token.transferFrom(
            liquidity,
            bob,
            amount
        );
    }


    function test_transferFrom_revertsZeroRecipient()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            100 ether
        );

        vm.prank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors
                    .ERC20InvalidReceiver
                    .selector,
                address(0)
            )
        );

        token.transferFrom(
            liquidity,
            address(0),
            100 ether
        );
    }


    // =============================================================
    // BURN
    // =============================================================

    function test_burn_success()
        public
    {
        uint256 amount =
            100 ether;

        vm.prank(liquidity);

        token.burn(
            amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertEq(
            token.totalSupply(),
            MAX_SUPPLY - amount
        );
    }


    function test_burn_zeroAmount()
        public
    {
        uint256 beforeSupply =
            token.totalSupply();

        uint256 beforeBalance =
            token.balanceOf(
                liquidity
            );

        vm.prank(liquidity);

        token.burn(
            0
        );

        assertEq(
            token.totalSupply(),
            beforeSupply
        );

        assertEq(
            token.balanceOf(liquidity),
            beforeBalance
        );
    }


    function test_burn_revertsInsufficientBalance()
        public
    {
        uint256 balance =
            token.balanceOf(
                liquidity
            );

        vm.prank(liquidity);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors
                    .ERC20InsufficientBalance
                    .selector,
                liquidity,
                balance,
                balance + 1
            )
        );

        token.burn(
            balance + 1
        );
    }


    function test_burn_doesNotAffectOtherBalances()
        public
    {
        uint256 communityBefore =
            token.balanceOf(
                community
            );

        uint256 treasuryBefore =
            token.balanceOf(
                treasury
            );

        vm.prank(liquidity);

        token.burn(
            100 ether
        );

        assertEq(
            token.balanceOf(community),
            communityBefore
        );

        assertEq(
            token.balanceOf(treasury),
            treasuryBefore
        );
    }


    function test_burnFrom_success()
        public
    {
        uint256 amount =
            100 ether;

        vm.prank(liquidity);

        token.approve(
            alice,
            amount
        );

        vm.prank(alice);

        token.burnFrom(
            liquidity,
            amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertEq(
            token.totalSupply(),
            MAX_SUPPLY - amount
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            0
        );
    }


    function test_burnFrom_maxAllowanceDoesNotDecrease()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            type(uint256).max
        );

        vm.prank(alice);

        token.burnFrom(
            liquidity,
            100 ether
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            type(uint256).max
        );
    }


    function test_burnFrom_revertsInsufficientAllowance()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            50 ether
        );

        vm.prank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors
                    .ERC20InsufficientAllowance
                    .selector,
                alice,
                50 ether,
                100 ether
            )
        );

        token.burnFrom(
            liquidity,
            100 ether
        );
    }


    function test_burnFrom_revertsInsufficientBalance()
        public
    {
        uint256 amount =
            LIQUIDITY_ALLOCATION + 1;

        vm.prank(liquidity);

        token.approve(
            alice,
            amount
        );

        vm.prank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors
                    .ERC20InsufficientBalance
                    .selector,
                liquidity,
                LIQUIDITY_ALLOCATION,
                amount
            )
        );

        token.burnFrom(
            liquidity,
            amount
        );
    }


    // =============================================================
    // PAUSABLE
    // =============================================================

    function test_ownerCanPause()
        public
    {
        token.pause();

        assertTrue(
            token.paused()
        );
    }


    function test_ownerCanUnpause()
        public
    {
        token.pause();

        token.unpause();

        assertFalse(
            token.paused()
        );
    }


    function test_nonOwnerCannotPause()
        public
    {
        vm.prank(attacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable
                    .OwnableUnauthorizedAccount
                    .selector,
                attacker
            )
        );

        token.pause();
    }


    function test_nonOwnerCannotUnpause()
        public
    {
        token.pause();

        vm.prank(attacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable
                    .OwnableUnauthorizedAccount
                    .selector,
                attacker
            )
        );

        token.unpause();
    }


    function test_pause_revertsSecondPause()
        public
    {
        token.pause();

        vm.expectRevert(
            Pausable
                .EnforcedPause
                .selector
        );

        token.pause();
    }


    function test_unpause_revertsWhenNotPaused()
        public
    {
        vm.expectRevert(
            Pausable
                .ExpectedPause
                .selector
        );

        token.unpause();
    }


    function test_pause_blocksTransfer()
        public
    {
        token.pause();

        vm.prank(liquidity);

        vm.expectRevert(
            Pausable
                .EnforcedPause
                .selector
        );

        token.transfer(
            alice,
            100 ether
        );
    }


    function test_pause_blocksTransferFrom()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            100 ether
        );

        token.pause();

        vm.prank(alice);

        vm.expectRevert(
            Pausable
                .EnforcedPause
                .selector
        );

        token.transferFrom(
            liquidity,
            bob,
            100 ether
        );
    }


    function test_pause_blocksBurn()
        public
    {
        token.pause();

        vm.prank(liquidity);

        vm.expectRevert(
            Pausable
                .EnforcedPause
                .selector
        );

        token.burn(
            100 ether
        );
    }


    function test_pause_blocksBurnFrom()
        public
    {
        vm.prank(liquidity);

        token.approve(
            alice,
            100 ether
        );

        token.pause();

        vm.prank(alice);

        vm.expectRevert(
            Pausable
                .EnforcedPause
                .selector
        );

        token.burnFrom(
            liquidity,
            100 ether
        );
    }


    function test_pause_doesNotBlockApprove()
        public
    {
        token.pause();

        vm.prank(liquidity);

        bool success =
            token.approve(
                alice,
                100 ether
            );

        assertTrue(
            success
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            100 ether
        );
    }


    function test_pause_doesNotChangeSupplyOrBalances()
        public
    {
        uint256 supplyBefore =
            token.totalSupply();

        uint256 liquidityBefore =
            token.balanceOf(
                liquidity
            );

        uint256 communityBefore =
            token.balanceOf(
                community
            );

        token.pause();

        assertEq(
            token.totalSupply(),
            supplyBefore
        );

        assertEq(
            token.balanceOf(liquidity),
            liquidityBefore
        );

        assertEq(
            token.balanceOf(community),
            communityBefore
        );
    }


    function test_unpause_restoresTransfer()
        public
    {
        token.pause();

        token.unpause();

        vm.prank(liquidity);

        token.transfer(
            alice,
            100 ether
        );

        assertEq(
            token.balanceOf(alice),
            100 ether
        );
    }


    function test_unpause_restoresBurn()
        public
    {
        token.pause();

        token.unpause();

        vm.prank(liquidity);

        token.burn(
            100 ether
        );

        assertEq(
            token.totalSupply(),
            MAX_SUPPLY - 100 ether
        );
    }


    // =============================================================
    // OWNABLE2STEP
    // =============================================================

    function test_transferOwnership_setsPendingOwner()
        public
    {
        token.transferOwnership(
            alice
        );

        assertEq(
            token.owner(),
            address(this)
        );

        assertEq(
            token.pendingOwner(),
            alice
        );
    }


    function test_pendingOwnerCanAcceptOwnership()
        public
    {
        token.transferOwnership(
            alice
        );

        vm.prank(alice);

        token.acceptOwnership();

        assertEq(
            token.owner(),
            alice
        );

        assertEq(
            token.pendingOwner(),
            address(0)
        );
    }


    function test_pendingOwnerCannotUseOwnerFunctionsBeforeAcceptance()
        public
    {
        token.transferOwnership(
            alice
        );

        vm.prank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable
                    .OwnableUnauthorizedAccount
                    .selector,
                alice
            )
        );

        token.pause();
    }


    function test_oldOwnerLosesPermissionAfterAcceptance()
        public
    {
        token.transferOwnership(
            alice
        );

        vm.prank(alice);

        token.acceptOwnership();

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable
                    .OwnableUnauthorizedAccount
                    .selector,
                address(this)
            )
        );

        token.pause();
    }


    function test_newOwnerCanPauseAfterAcceptance()
        public
    {
        token.transferOwnership(
            alice
        );

        vm.prank(alice);

        token.acceptOwnership();

        vm.prank(alice);

        token.pause();

        assertTrue(
            token.paused()
        );
    }


    function test_nonOwnerCannotTransferOwnership()
        public
    {
        vm.prank(attacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable
                    .OwnableUnauthorizedAccount
                    .selector,
                attacker
            )
        );

        token.transferOwnership(
            alice
        );
    }


    function test_nonPendingOwnerCannotAcceptOwnership()
        public
    {
        token.transferOwnership(
            alice
        );

        vm.prank(bob);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable
                    .OwnableUnauthorizedAccount
                    .selector,
                bob
            )
        );

        token.acceptOwnership();
    }


    function test_transferOwnershipCanReplacePendingOwner()
        public
    {
        token.transferOwnership(
            alice
        );

        token.transferOwnership(
            bob
        );

        assertEq(
            token.owner(),
            address(this)
        );

        assertEq(
            token.pendingOwner(),
            bob
        );
    }


    // =============================================================
    // ERC20 PERMIT
    // =============================================================

    function test_permit_nonceInitiallyZero()
        public
        view
    {
        address permitOwner =
            vm.addr(
                PERMIT_OWNER_PK
            );

        assertEq(
            token.nonces(
                permitOwner
            ),
            0
        );
    }


    function test_permit_domainSeparatorNonZero()
        public
        view
    {
        assertTrue(
            token.DOMAIN_SEPARATOR() !=
                bytes32(0)
        );
    }


    function test_permit_success()
        public
    {
        address permitOwner =
            vm.addr(
                PERMIT_OWNER_PK
            );

        uint256 amount =
            100 ether;

        uint256 deadline =
            block.timestamp +
            1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                PERMIT_OWNER_PK,
                permitOwner,
                alice,
                amount,
                deadline
            );

        token.permit(
            permitOwner,
            alice,
            amount,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.allowance(
                permitOwner,
                alice
            ),
            amount
        );

        assertEq(
            token.nonces(
                permitOwner
            ),
            1
        );
    }


    function test_permit_replayReverts()
        public
    {
        address permitOwner =
            vm.addr(
                PERMIT_OWNER_PK
            );

        uint256 amount =
            100 ether;

        uint256 deadline =
            block.timestamp +
            1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                PERMIT_OWNER_PK,
                permitOwner,
                alice,
                amount,
                deadline
            );

        token.permit(
            permitOwner,
            alice,
            amount,
            deadline,
            v,
            r,
            s
        );

        vm.expectRevert();

        token.permit(
            permitOwner,
            alice,
            amount,
            deadline,
            v,
            r,
            s
        );
    }


    function test_permit_expiredReverts()
        public
    {
        vm.warp(
            10 days
        );

        address permitOwner =
            vm.addr(
                PERMIT_OWNER_PK
            );

        uint256 deadline =
            block.timestamp - 1;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                PERMIT_OWNER_PK,
                permitOwner,
                alice,
                100 ether,
                deadline
            );

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20Permit
                    .ERC2612ExpiredSignature
                    .selector,
                deadline
            )
        );

        token.permit(
            permitOwner,
            alice,
            100 ether,
            deadline,
            v,
            r,
            s
        );
    }


    function test_permit_wrongSignerReverts()
        public
    {
        address permitOwner =
            vm.addr(
                PERMIT_OWNER_PK
            );

        address wrongSigner =
            vm.addr(
                WRONG_SIGNER_PK
            );

        uint256 amount =
            100 ether;

        uint256 deadline =
            block.timestamp +
            1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                WRONG_SIGNER_PK,
                permitOwner,
                alice,
                amount,
                deadline
            );

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20Permit
                    .ERC2612InvalidSigner
                    .selector,
                wrongSigner,
                permitOwner
            )
        );

        token.permit(
            permitOwner,
            alice,
            amount,
            deadline,
            v,
            r,
            s
        );
    }


    function test_permit_worksWhilePaused()
        public
    {
        address permitOwner =
            vm.addr(
                PERMIT_OWNER_PK
            );

        uint256 amount =
            100 ether;

        uint256 deadline =
            block.timestamp +
            1 days;

        token.pause();

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                PERMIT_OWNER_PK,
                permitOwner,
                alice,
                amount,
                deadline
            );

        token.permit(
            permitOwner,
            alice,
            amount,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.allowance(
                permitOwner,
                alice
            ),
            amount
        );
    }


    function test_permit_canBeUsedForTransferFrom()
        public
    {
        address permitOwner =
            vm.addr(
                PERMIT_OWNER_PK
            );

        uint256 amount =
            100 ether;

        vm.prank(liquidity);

        token.transfer(
            permitOwner,
            amount
        );

        uint256 deadline =
            block.timestamp +
            1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                PERMIT_OWNER_PK,
                permitOwner,
                alice,
                amount,
                deadline
            );

        token.permit(
            permitOwner,
            alice,
            amount,
            deadline,
            v,
            r,
            s
        );

        vm.prank(alice);

        token.transferFrom(
            permitOwner,
            bob,
            amount
        );

        assertEq(
            token.balanceOf(bob),
            amount
        );

        assertEq(
            token.balanceOf(permitOwner),
            0
        );

        assertEq(
            token.allowance(
                permitOwner,
                alice
            ),
            0
        );
    }


    // =============================================================
    // FUZZ
    // =============================================================

    function testFuzz_transferPreservesSupply(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                LIQUIDITY_ALLOCATION
            );

        uint256 supplyBefore =
            token.totalSupply();

        vm.prank(liquidity);

        token.transfer(
            alice,
            amount
        );

        assertEq(
            token.totalSupply(),
            supplyBefore
        );

        assertEq(
            token.balanceOf(alice),
            amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );
    }


    function testFuzz_burnReducesSupplyExactly(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                LIQUIDITY_ALLOCATION
            );

        uint256 supplyBefore =
            token.totalSupply();

        vm.prank(liquidity);

        token.burn(
            amount
        );

        assertEq(
            token.totalSupply(),
            supplyBefore - amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertLe(
            token.totalSupply(),
            MAX_SUPPLY
        );
    }


    function testFuzz_transferFromConsumesExactAllowance(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                LIQUIDITY_ALLOCATION
            );

        vm.prank(liquidity);

        token.approve(
            alice,
            amount
        );

        vm.prank(alice);

        token.transferFrom(
            liquidity,
            bob,
            amount
        );

        assertEq(
            token.balanceOf(bob),
            amount
        );

        assertEq(
            token.allowance(
                liquidity,
                alice
            ),
            0
        );
    }


    function testFuzz_burnFromReducesSupplyExactly(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                LIQUIDITY_ALLOCATION
            );

        vm.prank(liquidity);

        token.approve(
            alice,
            amount
        );

        uint256 supplyBefore =
            token.totalSupply();

        vm.prank(alice);

        token.burnFrom(
            liquidity,
            amount
        );

        assertEq(
            token.totalSupply(),
            supplyBefore - amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );
    }


    function testFuzz_transferBetweenAllocationsPreservesCombinedBalance(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                LIQUIDITY_ALLOCATION
            );

        uint256 combinedBefore =
            token.balanceOf(
                liquidity
            )
            +
            token.balanceOf(
                community
            );

        vm.prank(liquidity);

        token.transfer(
            community,
            amount
        );

        uint256 combinedAfter =
            token.balanceOf(
                liquidity
            )
            +
            token.balanceOf(
                community
            );

        assertEq(
            combinedAfter,
            combinedBefore
        );
    }


    // =============================================================
    // SUPPLY / SECURITY INVARIANTS
    // =============================================================

    function test_totalSupplyNeverExceedsMaxSupply()
        public
    {
        assertEq(
            token.totalSupply(),
            MAX_SUPPLY
        );

        vm.prank(liquidity);

        token.burn(
            100 ether
        );

        assertLt(
            token.totalSupply(),
            MAX_SUPPLY
        );

        assertLe(
            token.totalSupply(),
            token.MAX_SUPPLY()
        );
    }


    function test_noExternalMintFunctionExists()
        public
    {
        (
            bool success,
        ) =
            address(token).call(
                abi.encodeWithSignature(
                    "mint(address,uint256)",
                    alice,
                    1 ether
                )
            );

        assertFalse(
            success
        );

        assertEq(
            token.totalSupply(),
            MAX_SUPPLY
        );
    }


    function test_attackerCannotPause()
        public
    {
        vm.prank(attacker);

        vm.expectRevert();

        token.pause();

        assertFalse(
            token.paused()
        );
    }


    function test_attackerCannotChangeOwner()
        public
    {
        vm.prank(attacker);

        vm.expectRevert();

        token.transferOwnership(
            attacker
        );

        assertEq(
            token.owner(),
            address(this)
        );
    }


    // =============================================================
    // INTERNAL HELPERS
    // =============================================================

    function _signPermit(
        uint256 privateKey,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline
    )
        internal
        view
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        uint256 nonce =
            token.nonces(
                owner
            );

        bytes32 permitTypeHash =
            keccak256(
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
            );

        bytes32 structHash =
            keccak256(
                abi.encode(
                    permitTypeHash,
                    owner,
                    spender,
                    value,
                    nonce,
                    deadline
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
            v,
            r,
            s
        ) =
            vm.sign(
                privateKey,
                digest
            );
    }
}