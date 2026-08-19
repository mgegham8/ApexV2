// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";

import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterAddLiquidityETHAdversarialTest is Test {
    ApexV2Factory internal factory;
    ApexV2Router internal router;
    WETH9 internal weth;
    MockERC20 internal token;

    address internal alice = address(0xA11CE);

    uint256 internal constant TOKEN_BALANCE = 1_000_000 ether;
    uint256 internal constant ETH_BALANCE = 1_000_000 ether;

    function setUp() public {
        weth = new WETH9();

        factory = new ApexV2Factory(
            address(this)
        );

        router = new ApexV2Router(
            address(factory),
            address(weth)
        );

        token = new MockERC20(
            "Token",
            "TKN"
        );

        token.mint(
            alice,
            TOKEN_BALANCE
        );

        vm.deal(
            alice,
            ETH_BALANCE
        );

        vm.prank(alice);

        token.approve(
            address(router),
            type(uint256).max
        );
    }

    function test_addLiquidityETH_initialLiquidity_usesDesiredAmounts()
        public
    {
        uint256 tokenDesired = 100 ether;
        uint256 ethDesired = 10 ether;

        vm.prank(alice);

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) =
            router.addLiquidityETH{
                value: ethDesired
            }(
                address(token),
                tokenDesired,
                tokenDesired,
                ethDesired,
                alice,
                block.timestamp
            );

        assertEq(
            amountToken,
            tokenDesired
        );

        assertEq(
            amountETH,
            ethDesired
        );

        assertGt(
            liquidity,
            0
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
            token.balanceOf(pair),
            tokenDesired
        );

        assertEq(
            weth.balanceOf(pair),
            ethDesired
        );
    }

    function test_addLiquidityETH_existingPool_usesETHOptimal_andRefundsExcessETH()
        public
    {
        vm.startPrank(alice);

        router.addLiquidityETH{
            value: 10 ether
        }(
            address(token),
            100 ether,
            0,
            0,
            alice,
            block.timestamp
        );

        uint256 aliceETHBefore =
            alice.balance;

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) =
            router.addLiquidityETH{
                value: 20 ether
            }(
                address(token),
                100 ether,
                0,
                0,
                alice,
                block.timestamp
            );

        vm.stopPrank();

        assertEq(
            amountToken,
            100 ether
        );

        assertEq(
            amountETH,
            10 ether
        );

        assertGt(
            liquidity,
            0
        );

        assertEq(
            alice.balance,
            aliceETHBefore - 10 ether
        );
    }

    function test_addLiquidityETH_existingPool_usesTokenOptimal()
        public
    {
        vm.startPrank(alice);

        router.addLiquidityETH{
            value: 10 ether
        }(
            address(token),
            100 ether,
            0,
            0,
            alice,
            block.timestamp
        );

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) =
            router.addLiquidityETH{
                value: 5 ether
            }(
                address(token),
                100 ether,
                0,
                0,
                alice,
                block.timestamp
            );

        vm.stopPrank();

        assertEq(
            amountToken,
            50 ether
        );

        assertEq(
            amountETH,
            5 ether
        );

        assertGt(
            liquidity,
            0
        );
    }

    function test_addLiquidityETH_revertsWhenETHOptimalBelowMinimum()
        public
    {
        vm.startPrank(alice);

        router.addLiquidityETH{
            value: 10 ether
        }(
            address(token),
            100 ether,
            0,
            0,
            alice,
            block.timestamp
        );

        vm.expectRevert(
            bytes(
                "ApexV2Router: ETH_LOW"
            )
        );

        router.addLiquidityETH{
            value: 20 ether
        }(
            address(token),
            100 ether,
            0,
            11 ether,
            alice,
            block.timestamp
        );

        vm.stopPrank();
    }

    function test_addLiquidityETH_revertsWhenTokenOptimalBelowMinimum()
        public
    {
        vm.startPrank(alice);

        router.addLiquidityETH{
            value: 10 ether
        }(
            address(token),
            100 ether,
            0,
            0,
            alice,
            block.timestamp
        );

        vm.expectRevert(
            bytes(
                "ApexV2Router: TOKEN_LOW"
            )
        );

        router.addLiquidityETH{
            value: 5 ether
        }(
            address(token),
            100 ether,
            51 ether,
            0,
            alice,
            block.timestamp
        );

        vm.stopPrank();
    }

    function test_addLiquidityETH_revertsZeroToken()
        public
    {
        vm.prank(alice);

        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_ADDRESS"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(0),
            100 ether,
            0,
            0,
            alice,
            block.timestamp
        );
    }

    function test_addLiquidityETH_revertsWETHAsToken()
        public
    {
        vm.prank(alice);

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
            alice,
            block.timestamp
        );
    }

    function test_addLiquidityETH_revertsZeroRecipient()
        public
    {
        vm.prank(alice);

        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_RECIPIENT"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(token),
            100 ether,
            0,
            0,
            address(0),
            block.timestamp
        );
    }

    function test_addLiquidityETH_revertsZeroTokenDesired()
        public
    {
        vm.prank(alice);

        vm.expectRevert(
            bytes(
                "ApexV2Router: TOKEN_ZERO"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(token),
            0,
            0,
            0,
            alice,
            block.timestamp
        );
    }

    function test_addLiquidityETH_revertsZeroETH()
        public
    {
        vm.prank(alice);

        vm.expectRevert(
            bytes(
                "ApexV2Router: ETH_ZERO"
            )
        );

        router.addLiquidityETH(
            address(token),
            100 ether,
            0,
            0,
            alice,
            block.timestamp
        );
    }

    function test_addLiquidityETH_revertsExpiredDeadline()
        public
    {
        vm.warp(1000);

        vm.prank(alice);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(token),
            100 ether,
            0,
            0,
            alice,
            999
        );
    }

    function testFuzz_addLiquidityETH_existingPool_refundsExcessETH(
        uint96 tokenDesiredRaw,
        uint96 extraETHRaw
    )
        public
    {
        uint256 tokenDesired =
            bound(
                uint256(tokenDesiredRaw),
                1 ether,
                1_000 ether
            );

        uint256 extraETH =
            bound(
                uint256(extraETHRaw),
                1 wei,
                100 ether
            );

        vm.startPrank(alice);

        router.addLiquidityETH{
            value: 10 ether
        }(
            address(token),
            100 ether,
            0,
            0,
            alice,
            block.timestamp
        );

        uint256 expectedETH =
            tokenDesired * 10 ether / 100 ether;

        vm.assume(
            expectedETH > 0
        );

        uint256 suppliedETH =
            expectedETH + extraETH;

        vm.assume(
            suppliedETH <= alice.balance
        );

        uint256 aliceETHBefore =
            alice.balance;

        (
            uint256 amountToken,
            uint256 amountETH,
        ) =
            router.addLiquidityETH{
                value: suppliedETH
            }(
                address(token),
                tokenDesired,
                0,
                0,
                alice,
                block.timestamp
            );

        vm.stopPrank();

        assertEq(
            amountToken,
            tokenDesired
        );

        assertEq(
            amountETH,
            expectedETH
        );

        assertEq(
            alice.balance,
            aliceETHBefore - expectedETH
        );
    }
}