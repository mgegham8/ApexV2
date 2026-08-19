// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {ApexV2Factory} from "../src/contracts/ApexV2Factory.sol";

import {ApexV2Router} from "../src/contracts/ApexV2Router.sol";

import {MockERC20} from "../src/contracts/test/MockERC20.sol";

import {WETH9} from "../src/contracts/test/WETH9.sol";

interface ILPTokenCoverage {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract RejectETHCoverage {
    receive() external payable {
        revert("NO_ETH");
    }
}

contract ApexV2RouterFinalCoverageTest is Test {
    ApexV2Factory internal factory;
    ApexV2Router internal router;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    WETH9 internal weth;

    address internal alice;

    uint256 internal constant DEADLINE_OFFSET = 1 days;

    receive() external payable {}

    // =============================================================
    // SETUP
    // =============================================================

    function setUp() public {
        alice = makeAddr("alice");

        weth = new WETH9();

        factory = new ApexV2Factory(address(this));

        router = new ApexV2Router(address(factory), address(weth));

        tokenA = new MockERC20("Token A", "TKA");

        tokenB = new MockERC20("Token B", "TKB");

        tokenA.mint(address(this), 10_000_000 ether);

        tokenB.mint(address(this), 10_000_000 ether);

        assertTrue(tokenA.approve(address(router), type(uint256).max));

        assertTrue(tokenB.approve(address(router), type(uint256).max));

        vm.deal(address(this), 10_000 ether);
    }

    // =============================================================
    // ADD LIQUIDITY
    // A-OPTIMAL BRANCH
    // =============================================================

    function test_addLiquidity_existingPool_AOptimal_exactCoverage() public {
        _createTokenTokenPool(1_000 ether, 2_000 ether);

        address pair = factory.getPair(address(tokenA), address(tokenB));

        (uint112 reserve0Before, uint112 reserve1Before,) = _getPairReserves(pair);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            300 ether,
            100 ether,
            200 ether,
            address(this),
            block.timestamp + DEADLINE_OFFSET
        );

        /*
         * Existing pool ratio:
         *
         * A : B = 1 : 2
         *
         * 100 A requires exactly 200 B.
         *
         * amountBOptimal = 200 B
         * amountBDesired = 300 B
         *
         * Therefore:
         *
         * amountBOptimal <= amountBDesired
         *
         * and Router must execute:
         *
         * amountA = amountADesired;
         * amountB = amountBOptimal;
         */

        assertEq(amountA, 100 ether);

        assertEq(amountB, 200 ether);

        assertGt(liquidity, 0);

        (uint112 reserve0After, uint112 reserve1After,) = _getPairReserves(pair);

        if (address(tokenA) < address(tokenB)) {
            assertEq(uint256(reserve0After), uint256(reserve0Before) + 100 ether);

            assertEq(uint256(reserve1After), uint256(reserve1Before) + 200 ether);
        } else {
            assertEq(uint256(reserve0After), uint256(reserve0Before) + 200 ether);

            assertEq(uint256(reserve1After), uint256(reserve1Before) + 100 ether);
        }
    }

    // =============================================================
    // ADD LIQUIDITY
    // B-OPTIMAL BRANCH
    // =============================================================

    function test_addLiquidity_existingPool_BOptimal_exactCoverage() public {
        _createTokenTokenPool(1_000 ether, 2_000 ether);

        address pair = factory.getPair(address(tokenA), address(tokenB));

        (uint112 reserve0Before, uint112 reserve1Before,) = _getPairReserves(pair);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            200 ether,
            100 ether,
            50 ether,
            100 ether,
            address(this),
            block.timestamp + DEADLINE_OFFSET
        );

        /*
         * Existing ratio:
         *
         * A : B = 1 : 2
         *
         * Desired:
         * A = 200
         * B = 100
         *
         * 200 A would require 400 B,
         * therefore first branch cannot be used.
         *
         * Using 100 B requires:
         *
         * amountAOptimal = 50 A.
         *
         * Router must execute:
         *
         * amountA = amountAOptimal;
         * amountB = amountBDesired;
         */

        assertEq(amountA, 50 ether);

        assertEq(amountB, 100 ether);

        assertGt(liquidity, 0);

        (uint112 reserve0After, uint112 reserve1After,) = _getPairReserves(pair);

        if (address(tokenA) < address(tokenB)) {
            assertEq(uint256(reserve0After), uint256(reserve0Before) + 50 ether);

            assertEq(uint256(reserve1After), uint256(reserve1Before) + 100 ether);
        } else {
            assertEq(uint256(reserve0After), uint256(reserve0Before) + 100 ether);

            assertEq(uint256(reserve1After), uint256(reserve1Before) + 50 ether);
        }
    }

    // =============================================================
    // ADD LIQUIDITY ETH
    // INITIAL POOL BRANCH
    // =============================================================

    function test_addLiquidityETH_initialPool_exactCoverage() public {
        uint256 tokenAmount = 1_000 ether;

        uint256 ethAmount = 10 ether;

        uint256 ethBefore = address(this).balance;

        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(tokenA), tokenAmount, tokenAmount, ethAmount, address(this), block.timestamp + DEADLINE_OFFSET
        );

        assertEq(amountToken, tokenAmount);

        assertEq(amountETH, ethAmount);

        assertGt(liquidity, 0);

        assertEq(address(this).balance, ethBefore - ethAmount);

        address pair = factory.getPair(address(tokenA), address(weth));

        assertTrue(pair != address(0));

        assertEq(tokenA.balanceOf(pair), tokenAmount);

        assertEq(weth.balanceOf(pair), ethAmount);

        assertEq(address(router).balance, 0);

        assertEq(weth.balanceOf(address(router)), 0);
    }

    // =============================================================
    // ADD LIQUIDITY ETH
    // ETH-OPTIMAL BRANCH + REFUND
    // =============================================================

    function test_addLiquidityETH_existingPool_ETHOptimal_exactCoverage() public {
        _createTokenETHPool(1_000 ether, 10 ether);

        /*
         * Pool:
         *
         * 1000 Token : 10 ETH
         *
         * Desired:
         *
         * 100 Token : 2 ETH
         *
         * Correct ETH amount:
         *
         * 100 * 10 / 1000 = 1 ETH
         *
         * Router therefore executes:
         *
         * amountToken = amountTokenDesired;
         * amountETH = amountETHOptimal;
         *
         * and refunds 1 ETH.
         */

        uint256 ethBefore = address(this).balance;

        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidityETH{value: 2 ether}(
            address(tokenA), 100 ether, 100 ether, 1 ether, address(this), block.timestamp + DEADLINE_OFFSET
        );

        assertEq(amountToken, 100 ether);

        assertEq(amountETH, 1 ether);

        assertGt(liquidity, 0);

        /*
         * msg.value = 2 ETH
         * actual liquidity = 1 ETH
         * refund = 1 ETH
         *
         * Net balance decrease = 1 ETH.
         */

        assertEq(address(this).balance, ethBefore - 1 ether);

        assertEq(address(router).balance, 0);

        assertEq(weth.balanceOf(address(router)), 0);
    }

    // =============================================================
    // ADD LIQUIDITY ETH
    // TOKEN-OPTIMAL BRANCH
    // =============================================================

    function test_addLiquidityETH_existingPool_TokenOptimal_exactCoverage() public {
        _createTokenETHPool(1_000 ether, 10 ether);

        /*
         * Pool:
         *
         * 1000 Token : 10 ETH
         *
         * Desired:
         *
         * 200 Token : 1 ETH
         *
         * 200 Token requires 2 ETH,
         * but only 1 ETH was supplied.
         *
         * Router therefore calculates:
         *
         * amountTokenOptimal =
         * 1 ETH * 1000 Token / 10 ETH
         * = 100 Token
         *
         * and executes:
         *
         * amountToken = amountTokenOptimal;
         * amountETH = msg.value;
         */

        uint256 ethBefore = address(this).balance;

        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidityETH{value: 1 ether}(
            address(tokenA), 200 ether, 100 ether, 1 ether, address(this), block.timestamp + DEADLINE_OFFSET
        );

        assertEq(amountToken, 100 ether);

        assertEq(amountETH, 1 ether);

        assertGt(liquidity, 0);

        assertEq(address(this).balance, ethBefore - 1 ether);

        assertEq(address(router).balance, 0);

        assertEq(weth.balanceOf(address(router)), 0);
    }

    // =============================================================
    // REMOVE LIQUIDITY ETH
    // FULL SUCCESS PATH
    // =============================================================

    function test_removeLiquidityETH_fullSuccessPath_exactCoverage() public {
        _createTokenETHPool(1_000 ether, 10 ether);

        address pair = factory.getPair(address(tokenA), address(weth));

        assertTrue(pair != address(0));

        uint256 lpBalance = ILPTokenCoverage(pair).balanceOf(address(this));

        assertGt(lpBalance, 0);

        assertTrue(ILPTokenCoverage(pair).approve(address(router), lpBalance));

        uint256 aliceTokenBefore = tokenA.balanceOf(alice);

        uint256 aliceETHBefore = alice.balance;

        (uint256 amountToken, uint256 amountETH) =
            router.removeLiquidityETH(address(tokenA), lpBalance, 0, 0, alice, block.timestamp + DEADLINE_OFFSET);

        assertGt(amountToken, 0);

        assertGt(amountETH, 0);

        assertEq(tokenA.balanceOf(alice), aliceTokenBefore + amountToken);

        assertEq(alice.balance, aliceETHBefore + amountETH);

        assertEq(ILPTokenCoverage(pair).balanceOf(address(this)), 0);

        /*
         * Router must not retain token, WETH or ETH dust.
         */

        assertEq(tokenA.balanceOf(address(router)), 0);

        assertEq(weth.balanceOf(address(router)), 0);

        assertEq(address(router).balance, 0);
    }

    // =============================================================
    // REMOVE LIQUIDITY ETH
    // VALIDATION: ZERO TOKEN
    // =============================================================

    function test_removeLiquidityETH_revertsZeroToken_exactCoverage() public {
        vm.expectRevert(bytes("ApexV2Router: ZERO_ADDRESS"));

        router.removeLiquidityETH(address(0), 1, 0, 0, alice, block.timestamp + DEADLINE_OFFSET);
    }

    // =============================================================
    // REMOVE LIQUIDITY ETH
    // VALIDATION: WETH AS TOKEN
    // =============================================================

    function test_removeLiquidityETH_revertsWETHAsToken_exactCoverage() public {
        vm.expectRevert(bytes("ApexV2Router: INVALID_TOKEN"));

        router.removeLiquidityETH(address(weth), 1, 0, 0, alice, block.timestamp + DEADLINE_OFFSET);
    }

    // =============================================================
    // REMOVE LIQUIDITY ETH
    // VALIDATION: ZERO RECIPIENT
    // =============================================================

    function test_removeLiquidityETH_revertsZeroRecipient_exactCoverage() public {
        vm.expectRevert(bytes("ApexV2Router: ZERO_RECIPIENT"));

        router.removeLiquidityETH(address(tokenA), 1, 0, 0, address(0), block.timestamp + DEADLINE_OFFSET);
    }

    // =============================================================
    // REMOVE LIQUIDITY ETH
    // ETH RECIPIENT FAILURE
    // =============================================================

    function test_removeLiquidityETH_revertsWhenRecipientRejectsETH_exactCoverage() public {
        _createTokenETHPool(1_000 ether, 10 ether);

        address pair = factory.getPair(address(tokenA), address(weth));

        uint256 lpBalance = ILPTokenCoverage(pair).balanceOf(address(this));

        assertTrue(ILPTokenCoverage(pair).approve(address(router), lpBalance));

        RejectETHCoverage rejector = new RejectETHCoverage();

        uint256 lpBefore = ILPTokenCoverage(pair).balanceOf(address(this));

        uint256 tokenBefore = tokenA.balanceOf(address(rejector));

        vm.expectRevert(bytes("ApexV2Router: ETH_TRANSFER_FAILED"));

        router.removeLiquidityETH(
            address(tokenA), lpBalance, 0, 0, address(rejector), block.timestamp + DEADLINE_OFFSET
        );

        /*
         * Entire transaction must rollback.
         */

        assertEq(ILPTokenCoverage(pair).balanceOf(address(this)), lpBefore);

        assertEq(tokenA.balanceOf(address(rejector)), tokenBefore);

        assertEq(address(router).balance, 0);

        assertEq(tokenA.balanceOf(address(router)), 0);

        assertEq(weth.balanceOf(address(router)), 0);
    }

    // =============================================================
    // REMOVE LIQUIDITY ETH
    // EXACT MINIMUMS
    // =============================================================

    function test_removeLiquidityETH_exactMinimumsAccepted() public {
        _createTokenETHPool(1_000 ether, 10 ether);

        address pair = factory.getPair(address(tokenA), address(weth));

        uint256 lpBalance = ILPTokenCoverage(pair).balanceOf(address(this));

        assertGt(lpBalance, 0);

        /*
         * First determine exact outputs using the same pair state.
         *
         * We use a snapshot so the simulation can be reverted.
         */

        uint256 snapshot = vm.snapshotState();

        assertTrue(ILPTokenCoverage(pair).approve(address(router), lpBalance));

        (uint256 expectedToken, uint256 expectedETH) =
            router.removeLiquidityETH(address(tokenA), lpBalance, 0, 0, alice, block.timestamp + DEADLINE_OFFSET);

        assertTrue(vm.revertToState(snapshot));

        /*
         * After snapshot rollback, approve again.
         */

        assertTrue(ILPTokenCoverage(pair).approve(address(router), lpBalance));

        (uint256 actualToken, uint256 actualETH) = router.removeLiquidityETH(
            address(tokenA), lpBalance, expectedToken, expectedETH, alice, block.timestamp + DEADLINE_OFFSET
        );

        assertEq(actualToken, expectedToken);

        assertEq(actualETH, expectedETH);
    }

    // =============================================================
    // TOKEN/TOKEN LIQUIDITY HELPER
    // =============================================================

    function _createTokenTokenPool(uint256 amountA, uint256 amountB) internal {
        (uint256 usedA, uint256 usedB, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            amountA,
            amountB,
            address(this),
            block.timestamp + DEADLINE_OFFSET
        );

        assertEq(usedA, amountA);

        assertEq(usedB, amountB);

        assertGt(liquidity, 0);

        address pair = factory.getPair(address(tokenA), address(tokenB));

        assertTrue(pair != address(0));
    }

    // =============================================================
    // TOKEN/ETH LIQUIDITY HELPER
    // =============================================================

    function _createTokenETHPool(uint256 tokenAmount, uint256 ethAmount) internal {
        (uint256 usedToken, uint256 usedETH, uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(tokenA), tokenAmount, tokenAmount, ethAmount, address(this), block.timestamp + DEADLINE_OFFSET
        );

        assertEq(usedToken, tokenAmount);

        assertEq(usedETH, ethAmount);

        assertGt(liquidity, 0);

        address pair = factory.getPair(address(tokenA), address(weth));

        assertTrue(pair != address(0));
    }

    // =============================================================
    // RESERVE HELPER
    // =============================================================

    function _getPairReserves(address pair)
        internal
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)
    {
        (bool success, bytes memory data) = pair.staticcall(abi.encodeWithSignature("getReserves()"));

        require(success, "RESERVES_CALL_FAILED");

        (reserve0, reserve1, blockTimestampLast) = abi.decode(data, (uint112, uint112, uint32));
    }
}
