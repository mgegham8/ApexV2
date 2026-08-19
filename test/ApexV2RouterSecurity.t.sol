// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";

import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterSecurityTest is Test {
    ApexV2Factory internal factory;
    ApexV2Router internal router;
    WETH9 internal weth;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);

    uint256 internal constant INITIAL_BALANCE = 1_000_000 ether;

    function setUp() public {
        weth = new WETH9();

        factory = new ApexV2Factory(
            address(this)
        );

        router = new ApexV2Router(
            address(factory),
            address(weth)
        );

        tokenA = new MockERC20(
            "Token A",
            "TKA"
        );

        tokenB = new MockERC20(
            "Token B",
            "TKB"
        );

        tokenA.mint(
            ALICE,
            INITIAL_BALANCE
        );

        tokenB.mint(
            ALICE,
            INITIAL_BALANCE
        );

        tokenA.mint(
            BOB,
            INITIAL_BALANCE
        );

        tokenB.mint(
            BOB,
            INITIAL_BALANCE
        );

        vm.deal(
            ALICE,
            1_000 ether
        );

        vm.deal(
            BOB,
            1_000 ether
        );

        vm.startPrank(ALICE);

        tokenA.approve(
            address(router),
            type(uint256).max
        );

        tokenB.approve(
            address(router),
            type(uint256).max
        );

        vm.stopPrank();

        vm.startPrank(BOB);

        tokenA.approve(
            address(router),
            type(uint256).max
        );

        tokenB.approve(
            address(router),
            type(uint256).max
        );

        vm.stopPrank();
    }

    // ========================================================================
    // CONSTRUCTOR
    // ========================================================================

    function testConstructorRejectsZeroFactory()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_FACTORY"
            )
        );

        new ApexV2Router(
            address(0),
            address(weth)
        );
    }

    function testConstructorRejectsZeroWETH()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_WETH"
            )
        );

        new ApexV2Router(
            address(factory),
            address(0)
        );
    }

    function testConstructorStoresFactory()
        public
        view
    {
        assertEq(
            router.factory(),
            address(factory)
        );
    }

    function testConstructorStoresWETH()
        public
        view
    {
        assertEq(
            router.WETH(),
            address(weth)
        );
    }

    // ========================================================================
    // DEADLINE
    // ========================================================================

    function testDeadlineExactlyAtTimestampIsAccepted()
        public
    {
        vm.prank(ALICE);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            ALICE,
            block.timestamp
        );

        address pair =
            factory.getPair(
                address(tokenA),
                address(tokenB)
            );

        assertTrue(
            pair != address(0)
        );
    }

    function testAddLiquidityRejectsExpiredDeadline()
        public
    {
        vm.warp(100);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            ALICE,
            99
        );
    }

    // ========================================================================
    // ADD LIQUIDITY VALIDATION
    // ========================================================================

    function testAddLiquidityRejectsIdenticalTokens()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: IDENTICAL_TOKEN"
            )
        );

        router.addLiquidity(
            address(tokenA),
            address(tokenA),
            100 ether,
            100 ether,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    function testAddLiquidityRejectsZeroTokenA()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidity(
            address(0),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    function testAddLiquidityRejectsZeroTokenB()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidity(
            address(tokenA),
            address(0),
            100 ether,
            100 ether,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    function testAddLiquidityRejectsZeroRecipient()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            address(0),
            block.timestamp
        );
    }

    function testAddLiquidityRejectsZeroDesiredAmounts()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            0,
            0,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    // ========================================================================
    // ADD LIQUIDITY ETH
    // ========================================================================

    function testAddLiquidityETHRejectsExpiredDeadline()
        public
    {
        vm.warp(100);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(tokenA),
            100 ether,
            0,
            0,
            ALICE,
            99
        );
    }

    function testAddLiquidityETHRejectsWETHAsToken()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_TOKEN"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(weth),
            100 ether,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    function testAddLiquidityETHRejectsZeroToken()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(0),
            100 ether,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    function testAddLiquidityETHRejectsZeroRecipient()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(tokenA),
            100 ether,
            0,
            0,
            address(0),
            block.timestamp
        );
    }

    function testAddLiquidityETHRejectsZeroTokenDesired()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(tokenA),
            0,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    function testAddLiquidityETHRejectsZeroETH()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidityETH(
            address(tokenA),
            100 ether,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    function testAddLiquidityETHRejectsTokenBelowMinimum()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(tokenA),
            99 ether,
            100 ether,
            0,
            ALICE,
            block.timestamp
        );
    }

    function testAddLiquidityETHRejectsETHBelowMinimum()
        public
    {
        vm.prank(ALICE);

        vm.expectRevert();

        router.addLiquidityETH{
            value: 0.5 ether
        }(
            address(tokenA),
            100 ether,
            0,
            1 ether,
            ALICE,
            block.timestamp
        );
    }

    // ========================================================================
    // RECEIVE
    // ========================================================================

    function testReceiveRejectsETHFromNonWETH()
        public
    {
        vm.deal(
            address(this),
            10 ether
        );

        uint256 routerBalanceBefore =
            address(router).balance;

        (
            bool success,
            bytes memory returnData
        ) =
            address(router).call{
                value: 1 ether
            }("");

        assertFalse(
            success
        );

        assertEq(
            address(router).balance,
            routerBalanceBefore
        );

        assertGt(
            returnData.length,
            0
        );
    }

    function testRouterDoesNotAcceptArbitraryETH()
        public
    {
        vm.deal(
            ALICE,
            10 ether
        );

        uint256 aliceBefore =
            ALICE.balance;

        uint256 routerBefore =
            address(router).balance;

        vm.prank(ALICE);

        (
            bool success,
            bytes memory returnData
        ) =
            address(router).call{
                value: 0.5 ether
            }("");

        assertFalse(
            success
        );

        assertEq(
            address(router).balance,
            routerBefore
        );

        assertEq(
            ALICE.balance,
            aliceBefore
        );

        assertGt(
            returnData.length,
            0
        );
    }

    // ========================================================================
    // REMOVE LIQUIDITY
    // ========================================================================

    function testRemoveLiquidityRejectsExpiredDeadline()
        public
    {
        vm.warp(100);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            100,
            0,
            0,
            ALICE,
            99
        );
    }

    function testRemoveLiquidityETHRejectsExpiredDeadline()
        public
    {
        vm.warp(100);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.removeLiquidityETH(
            address(tokenA),
            100,
            0,
            0,
            ALICE,
            99
        );
    }

    // ========================================================================
    // TOKENS -> TOKENS PATH VALIDATION
    // ========================================================================

    function testSwapTokensForTokensRejectsExpiredDeadline()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.warp(100);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.swapExactTokensForTokens(
            100 ether,
            0,
            path,
            ALICE,
            99
        );
    }

    function testSwapTokensForTokensRejectsEmptyPath()
        public
    {
        address[] memory path =
            new address[](0);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForTokens(
            100 ether,
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    function testSwapTokensForTokensRejectsOneTokenPath()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(tokenA);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForTokens(
            100 ether,
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    function testSwapTokensForTokensZeroAmountDoesNotBypassPathCheck()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(tokenA);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INSUFFICIENT_INPUT"
            )
        );

        router.swapExactTokensForTokens(
            0,
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    // ========================================================================
    // ETH -> TOKENS PATH VALIDATION
    // ========================================================================

    function testSwapETHForTokensRejectsExpiredDeadline()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(weth);
        path[1] = address(tokenA);

        vm.warp(100);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.swapExactETHForTokens{
            value: 1 ether
        }(
            0,
            path,
            ALICE,
            99
        );
    }

    function testSwapETHForTokensRejectsEmptyPath()
        public
    {
        address[] memory path =
            new address[](0);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactETHForTokens{
            value: 1 ether
        }(
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    function testSwapETHForTokensRejectsOneTokenPath()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(weth);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactETHForTokens{
            value: 1 ether
        }(
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    function testSwapETHForTokensRejectsWrongFirstToken()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_WETH_PATH"
            )
        );

        router.swapExactETHForTokens{
            value: 1 ether
        }(
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    function testSwapETHForTokensZeroValueDoesNotBypassPathCheck()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(weth);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INSUFFICIENT_INPUT"
            )
        );

        router.swapExactETHForTokens(
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    // ========================================================================
    // TOKENS -> ETH PATH VALIDATION
    // ========================================================================

    function testSwapTokensForETHRejectsExpiredDeadline()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(weth);

        vm.warp(100);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.swapExactTokensForETH(
            100 ether,
            0,
            path,
            ALICE,
            99
        );
    }

    function testSwapTokensForETHRejectsEmptyPath()
        public
    {
        address[] memory path =
            new address[](0);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForETH(
            100 ether,
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    function testSwapTokensForETHRejectsOneTokenPath()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(tokenA);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForETH(
            100 ether,
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    function testSwapTokensForETHRejectsWrongLastToken()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_WETH_PATH"
            )
        );

        router.swapExactTokensForETH(
            100 ether,
            0,
            path,
            ALICE,
            block.timestamp
        );
    }
}