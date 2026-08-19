// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {
    ApexLaunchController
} from "../src/contracts/launch/ApexLaunchController.sol";

import {
    ApexVesting
} from "../src/contracts/launch/ApexVesting.sol";

import {
    ApexV2Factory
} from "../src/contracts/ApexV2Factory.sol";

import {
    ApexV2Router
} from "../src/contracts/ApexV2Router.sol";

import {
    MockERC20
} from "../src/contracts/test/MockERC20.sol";

import {
    WETH9
} from "../src/contracts/test/WETH9.sol";

import {
    IERC20 as OZ_IERC20
} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ApexV2LaunchControllerFinalSecurityTest is Test {
    ApexLaunchController internal controller;

    ApexV2Factory internal factory;
    ApexV2Router internal router;
    ApexVesting internal vesting;

    MockERC20 internal token;
    WETH9 internal weth;

    address internal attacker;
    address internal user;
    address internal newOwner;

    uint256 internal constant TOKEN_AMOUNT =
        100_000 ether;

    uint256 internal constant ETH_AMOUNT =
        100 ether;

    uint256 internal constant VESTING_AMOUNT =
        10_000 ether;

    uint256 internal constant CLIFF =
        30 days;

    uint256 internal constant DURATION =
        365 days;

    function setUp() public {
        attacker =
            makeAddr("attacker");

        user =
            makeAddr("user");

        newOwner =
            makeAddr("newOwner");

        token =
            new MockERC20(
                "Apex Token",
                "APEX"
            );

        weth =
            new WETH9();

        factory =
            new ApexV2Factory(
                address(this)
            );

        router =
            new ApexV2Router(
                address(factory),
                address(weth)
            );

        vesting =
            new ApexVesting(
                address(token)
            );

        controller =
            new ApexLaunchController(
                address(token),
                address(router),
                address(factory),
                address(vesting)
            );

        vesting.setOperator(
            address(controller),
            true
        );

        token.mint(
            address(controller),
            1_000_000 ether
        );

        token.mint(
            address(vesting),
            1_000_000 ether
        );

        vm.deal(
            address(this),
            10_000 ether
        );

        vm.deal(
            attacker,
            10_000 ether
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
            controller.owner(),
            address(this)
        );

        assertEq(
            controller.pendingOwner(),
            address(0)
        );
    }

    function test_constructor_setsDependencies()
        public
        view
    {
        assertEq(
            controller.token(),
            address(token)
        );

        assertEq(
            controller.router(),
            address(router)
        );

        assertEq(
            controller.factory(),
            address(factory)
        );

        assertEq(
            controller.vesting(),
            address(vesting)
        );
    }

    function test_constructor_initialState()
        public
        view
    {
        assertFalse(
            controller.launched()
        );

        assertEq(
            controller.lpToken(),
            address(0)
        );
    }

    function test_constructor_revertsZeroToken()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroToken.selector
        );

        new ApexLaunchController(
            address(0),
            address(router),
            address(factory),
            address(vesting)
        );
    }

    function test_constructor_revertsZeroRouter()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroRouter.selector
        );

        new ApexLaunchController(
            address(token),
            address(0),
            address(factory),
            address(vesting)
        );
    }

    function test_constructor_revertsZeroFactory()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroFactory.selector
        );

        new ApexLaunchController(
            address(token),
            address(router),
            address(0),
            address(vesting)
        );
    }

    function test_constructor_revertsZeroVesting()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroVesting.selector
        );

        new ApexLaunchController(
            address(token),
            address(router),
            address(factory),
            address(0)
        );
    }

    function test_constructor_revertsTokenWithoutCode()
        public
    {
        address eoa =
            makeAddr("tokenEOA");

        vm.expectRevert(
            ApexLaunchController.TokenHasNoCode.selector
        );

        new ApexLaunchController(
            eoa,
            address(router),
            address(factory),
            address(vesting)
        );
    }

    function test_constructor_revertsRouterWithoutCode()
        public
    {
        address eoa =
            makeAddr("routerEOA");

        vm.expectRevert(
            ApexLaunchController.RouterHasNoCode.selector
        );

        new ApexLaunchController(
            address(token),
            eoa,
            address(factory),
            address(vesting)
        );
    }

    function test_constructor_revertsFactoryWithoutCode()
        public
    {
        address eoa =
            makeAddr("factoryEOA");

        vm.expectRevert(
            ApexLaunchController.FactoryHasNoCode.selector
        );

        new ApexLaunchController(
            address(token),
            address(router),
            eoa,
            address(vesting)
        );
    }

    function test_constructor_revertsVestingWithoutCode()
        public
    {
        address eoa =
            makeAddr("vestingEOA");

        vm.expectRevert(
            ApexLaunchController.VestingHasNoCode.selector
        );

        new ApexLaunchController(
            address(token),
            address(router),
            address(factory),
            eoa
        );
    }

    // ============================================================
    // RECEIVE ETH
    // ============================================================

    function test_receiveRejectsArbitraryETH()
        public
    {
        vm.expectRevert(
            ApexLaunchController.UnauthorizedETHSender.selector
        );

        payable(address(controller)).transfer(
            1 ether
        );
    }

    function test_receiveAcceptsETHFromRouter()
        public
    {
        vm.deal(
            address(router),
            1 ether
        );

        vm.prank(
            address(router)
        );

        (bool success,) =
            address(controller).call{
                value: 1 ether
            }("");

        assertTrue(
            success
        );

        assertEq(
            address(controller).balance,
            1 ether
        );
    }

    // ============================================================
    // LAUNCH
    // ============================================================

    function test_launch_success()
        public
    {
        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );

        assertTrue(
            controller.launched()
        );

        address pair =
            factory.getPair(
                address(token),
                address(weth)
            );

        assertTrue(
            pair != address(0)
        );

        assertEq(
            controller.lpToken(),
            pair
        );

        assertGt(
            OZ_IERC20(pair).balanceOf(
                address(controller)
            ),
            0
        );
    }

    function test_launch_createsCorrectPair()
        public
    {
        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );

        address pair =
            factory.getPair(
                address(token),
                address(weth)
            );

        assertEq(
            controller.lpToken(),
            pair
        );

        assertEq(
            factory.getPair(
                address(weth),
                address(token)
            ),
            pair
        );
    }

    function test_launch_movesTokensIntoLiquidity()
        public
    {
        uint256 controllerBalanceBefore =
            token.balanceOf(
                address(controller)
            );

        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );

        uint256 controllerBalanceAfter =
            token.balanceOf(
                address(controller)
            );

        assertEq(
            controllerBalanceBefore -
                controllerBalanceAfter,
            TOKEN_AMOUNT
        );
    }

    function test_launch_clearsRouterAllowance()
        public
    {
        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );

        assertEq(
            token.allowance(
                address(controller),
                address(router)
            ),
            0
        );
    }

    function test_launch_emitsEvent()
        public
    {
        vm.recordLogs();

        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );

        Vm.Log[] memory logs =
            vm.getRecordedLogs();

        bytes32 signature =
            keccak256(
                "Launched(address,uint256,uint256,uint256)"
            );

        bool found;

        for (
            uint256 i;
            i < logs.length;
            ++i
        ) {
            if (
                logs[i].emitter ==
                    address(controller) &&
                logs[i].topics.length > 0 &&
                logs[i].topics[0] ==
                    signature
            ) {
                found = true;
                break;
            }
        }

        assertTrue(
            found
        );
    }

    function test_launch_revertsNonOwner()
        public
    {
        vm.prank(
            attacker
        );

        vm.expectRevert(
            ApexLaunchController.NotOwner.selector
        );

        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function test_launch_revertsAlreadyLaunched()
        public
    {
        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );

        vm.expectRevert(
            ApexLaunchController.AlreadyLaunched.selector
        );

        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function test_launch_revertsZeroWETH()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroWETH.selector
        );

        controller.launch{
            value: ETH_AMOUNT
        }(
            address(0),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function test_launch_revertsWETHWithoutCode()
        public
    {
        address fakeWeth =
            makeAddr("fakeWeth");

        vm.expectRevert(
            ApexLaunchController.WETHHasNoCode.selector
        );

        controller.launch{
            value: ETH_AMOUNT
        }(
            fakeWeth,
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function test_launch_revertsZeroTokenAmount()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroTokenAmount.selector
        );

        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            0,
            ETH_AMOUNT
        );
    }

    function test_launch_revertsZeroETHAmount()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroETHAmount.selector
        );

        controller.launch(
            address(weth),
            TOKEN_AMOUNT,
            0
        );
    }

    function test_launch_revertsWrongETHAmount()
        public
    {
        vm.expectRevert(
            ApexLaunchController.WrongETHAmount.selector
        );

        controller.launch{
            value: ETH_AMOUNT - 1
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function test_launch_revertsTooMuchETH()
        public
    {
        vm.expectRevert(
            ApexLaunchController.WrongETHAmount.selector
        );

        controller.launch{
            value: ETH_AMOUNT + 1
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function test_launch_revertsInsufficientTokenBalance()
        public
    {
        uint256 balance =
            token.balanceOf(
                address(controller)
            );

        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            balance,
            ETH_AMOUNT
        );

        /*
         * Controller is now launched. Create a new controller
         * with insufficient balance for the failure path.
         */

        ApexLaunchController controller2 =
            new ApexLaunchController(
                address(token),
                address(router),
                address(factory),
                address(vesting)
            );

        vm.expectRevert(
            ApexLaunchController.InsufficientTokenBalance.selector
        );

        controller2.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function test_launch_revertsExistingPair()
        public
    {
        MockERC20 token2 =
            new MockERC20(
                "Token2",
                "TK2"
            );

        token2.mint(
            address(this),
            TOKEN_AMOUNT
        );

        token2.approve(
            address(router),
            type(uint256).max
        );

        router.addLiquidityETH{
            value: ETH_AMOUNT
        }(
            address(token2),
            TOKEN_AMOUNT,
            0,
            0,
            address(this),
            vm.getBlockTimestamp() +
                1 hours
        );

        ApexVesting vesting2 =
            new ApexVesting(
                address(token2)
            );

        ApexLaunchController controller2 =
            new ApexLaunchController(
                address(token2),
                address(router),
                address(factory),
                address(vesting2)
            );

        token2.mint(
            address(controller2),
            TOKEN_AMOUNT
        );

        vm.expectRevert(
            ApexLaunchController.PairAlreadyExists.selector
        );

        controller2.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function test_launchFailureDoesNotSetLaunched()
        public
    {
        ApexLaunchController controller2 =
            new ApexLaunchController(
                address(token),
                address(router),
                address(factory),
                address(vesting)
            );

        vm.expectRevert(
            ApexLaunchController.InsufficientTokenBalance.selector
        );

        controller2.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );

        assertFalse(
            controller2.launched()
        );

        assertEq(
            controller2.lpToken(),
            address(0)
        );
    }

    // ============================================================
    // VESTING
    // ============================================================

    function test_createVesting_success()
        public
    {
        uint256 start =
            vm.getBlockTimestamp();

        controller.createVesting(
            user,
            VESTING_AMOUNT,
            CLIFF,
            DURATION
        );

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(
                user
            );

        assertEq(
            schedule.totalAmount,
            VESTING_AMOUNT
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

    function test_createVesting_emitsEvent()
        public
    {
        vm.expectEmit(
            true,
            false,
            false,
            true
        );

        emit ApexLaunchController.VestingCreated(
            user,
            VESTING_AMOUNT,
            CLIFF,
            DURATION
        );

        controller.createVesting(
            user,
            VESTING_AMOUNT,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_revertsNonOwner()
        public
    {
        vm.prank(
            attacker
        );

        vm.expectRevert(
            ApexLaunchController.NotOwner.selector
        );

        controller.createVesting(
            user,
            VESTING_AMOUNT,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_revertsZeroUser()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroUser.selector
        );

        controller.createVesting(
            address(0),
            VESTING_AMOUNT,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_revertsZeroAmount()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroAmount.selector
        );

        controller.createVesting(
            user,
            0,
            CLIFF,
            DURATION
        );
    }

    function test_createVesting_revertsZeroDuration()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroDuration.selector
        );

        controller.createVesting(
            user,
            VESTING_AMOUNT,
            0,
            0
        );
    }

    function test_createVesting_revertsCliffGreaterThanDuration()
        public
    {
        vm.expectRevert(
            ApexLaunchController.InvalidCliff.selector
        );

        controller.createVesting(
            user,
            VESTING_AMOUNT,
            DURATION + 1,
            DURATION
        );
    }

    function test_createVesting_allowsCliffEqualDuration()
        public
    {
        controller.createVesting(
            user,
            VESTING_AMOUNT,
            DURATION,
            DURATION
        );

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(user);

        assertEq(
            schedule.cliff,
            DURATION
        );

        assertEq(
            schedule.duration,
            DURATION
        );
    }

    function test_createVesting_revertsIfControllerNotOperator()
        public
    {
        ApexVesting vesting2 =
            new ApexVesting(
                address(token)
            );

        token.mint(
            address(vesting2),
            VESTING_AMOUNT
        );

        ApexLaunchController controller2 =
            new ApexLaunchController(
                address(token),
                address(router),
                address(factory),
                address(vesting2)
            );

        vm.expectRevert(
            ApexVesting.NotOperator.selector
        );

        controller2.createVesting(
            user,
            VESTING_AMOUNT,
            CLIFF,
            DURATION
        );
    }

    // ============================================================
    // OWNERSHIP
    // ============================================================

    function test_transferOwnership_setsPendingOwner()
        public
    {
        controller.transferOwnership(
            newOwner
        );

        assertEq(
            controller.owner(),
            address(this)
        );

        assertEq(
            controller.pendingOwner(),
            newOwner
        );
    }

    function test_transferOwnership_emitsEvent()
        public
    {
        vm.expectEmit(
            true,
            true,
            false,
            true
        );

        emit ApexLaunchController.OwnershipTransferStarted(
            address(this),
            newOwner
        );

        controller.transferOwnership(
            newOwner
        );
    }

    function test_transferOwnership_revertsNonOwner()
        public
    {
        vm.prank(
            attacker
        );

        vm.expectRevert(
            ApexLaunchController.NotOwner.selector
        );

        controller.transferOwnership(
            newOwner
        );
    }

    function test_transferOwnership_revertsZeroOwner()
        public
    {
        vm.expectRevert(
            ApexLaunchController.ZeroOwner.selector
        );

        controller.transferOwnership(
            address(0)
        );
    }

    function test_transferOwnership_revertsSameOwner()
        public
    {
        vm.expectRevert(
            ApexLaunchController.SameOwner.selector
        );

        controller.transferOwnership(
            address(this)
        );
    }

    function test_pendingOwnerCanAcceptOwnership()
        public
    {
        controller.transferOwnership(
            newOwner
        );

        vm.prank(
            newOwner
        );

        controller.acceptOwnership();

        assertEq(
            controller.owner(),
            newOwner
        );

        assertEq(
            controller.pendingOwner(),
            address(0)
        );
    }

    function test_acceptOwnership_emitsEvent()
        public
    {
        controller.transferOwnership(
            newOwner
        );

        vm.expectEmit(
            true,
            true,
            false,
            true
        );

        emit ApexLaunchController.OwnershipTransferred(
            address(this),
            newOwner
        );

        vm.prank(
            newOwner
        );

        controller.acceptOwnership();
    }

    function test_acceptOwnership_revertsNonPendingOwner()
        public
    {
        controller.transferOwnership(
            newOwner
        );

        vm.prank(
            attacker
        );

        vm.expectRevert(
            ApexLaunchController.NotPendingOwner.selector
        );

        controller.acceptOwnership();
    }

    function test_oldOwnerLosesPermissionAfterTransfer()
        public
    {
        controller.transferOwnership(
            newOwner
        );

        vm.prank(
            newOwner
        );

        controller.acceptOwnership();

        vm.expectRevert(
            ApexLaunchController.NotOwner.selector
        );

        controller.createVesting(
            user,
            VESTING_AMOUNT,
            CLIFF,
            DURATION
        );
    }

    function test_newOwnerCanCreateVesting()
        public
    {
        controller.transferOwnership(
            newOwner
        );

        vm.prank(
            newOwner
        );

        controller.acceptOwnership();

        vm.prank(
            newOwner
        );

        controller.createVesting(
            user,
            VESTING_AMOUNT,
            CLIFF,
            DURATION
        );

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(user);

        assertEq(
            schedule.totalAmount,
            VESTING_AMOUNT
        );
    }

    function test_newOwnerCanLaunch()
        public
    {
        controller.transferOwnership(
            newOwner
        );

        vm.prank(
            newOwner
        );

        controller.acceptOwnership();

        vm.deal(
            newOwner,
            ETH_AMOUNT
        );

        vm.prank(
            newOwner
        );

        controller.launch{
            value: ETH_AMOUNT
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );

        assertTrue(
            controller.launched()
        );
    }

    function test_pendingOwnerCanBeReplaced()
        public
    {
        address owner2 =
            makeAddr("owner2");

        controller.transferOwnership(
            newOwner
        );

        controller.transferOwnership(
            owner2
        );

        assertEq(
            controller.pendingOwner(),
            owner2
        );

        vm.prank(
            newOwner
        );

        vm.expectRevert(
            ApexLaunchController.NotPendingOwner.selector
        );

        controller.acceptOwnership();

        vm.prank(
            owner2
        );

        controller.acceptOwnership();

        assertEq(
            controller.owner(),
            owner2
        );
    }

    // ============================================================
    // FUZZ
    // ============================================================

    function testFuzz_createVestingStoresExactValues(
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
                100_000 ether
            );

        uint256 duration =
            bound(
                uint256(rawDuration),
                1,
                10 * 365 days
            );

        uint256 cliff =
            bound(
                uint256(rawCliff),
                0,
                duration
            );

        uint256 start =
            vm.getBlockTimestamp();

        controller.createVesting(
            user,
            amount,
            cliff,
            duration
        );

        ApexVesting.Schedule memory schedule =
            vesting.getSchedule(user);

        assertEq(
            schedule.totalAmount,
            amount
        );

        assertEq(
            schedule.startTime,
            start
        );

        assertEq(
            schedule.cliff,
            cliff
        );

        assertEq(
            schedule.duration,
            duration
        );
    }

    function testFuzz_wrongETHAlwaysReverts(
        uint96 rawValue
    )
        public
    {
        uint256 supplied =
            bound(
                uint256(rawValue),
                0,
                1_000 ether
            );

        vm.assume(
            supplied != ETH_AMOUNT
        );

        vm.deal(
            address(this),
            supplied
        );

        vm.expectRevert(
            ApexLaunchController.WrongETHAmount.selector
        );

        controller.launch{
            value: supplied
        }(
            address(weth),
            TOKEN_AMOUNT,
            ETH_AMOUNT
        );
    }

    function testFuzz_ownershipTransfer(
        address candidate
    )
        public
    {
        vm.assume(
            candidate != address(0)
        );

        vm.assume(
            candidate != address(this)
        );

        controller.transferOwnership(
            candidate
        );

        assertEq(
            controller.pendingOwner(),
            candidate
        );

        vm.prank(
            candidate
        );

        controller.acceptOwnership();

        assertEq(
            controller.owner(),
            candidate
        );

        assertEq(
            controller.pendingOwner(),
            address(0)
        );
    }
}