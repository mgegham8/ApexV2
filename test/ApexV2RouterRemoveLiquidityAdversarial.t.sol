// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";

import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterRemoveLiquidityAdversarialTest is Test {
    ApexV2Factory internal factory;
    ApexV2Router internal router;
    WETH9 internal weth;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal alice = address(0xA11CE);

    uint256 internal constant TOKEN_BALANCE = 1_000_000 ether;

    uint256 internal constant ETH_BALANCE = 10_000 ether;

    function setUp() public {
        weth = new WETH9();

        factory = new ApexV2Factory(address(this));

        router = new ApexV2Router(address(factory), address(weth));

        tokenA = new MockERC20("Token A", "TKA");

        tokenB = new MockERC20("Token B", "TKB");

        tokenA.mint(alice, TOKEN_BALANCE);

        tokenB.mint(alice, TOKEN_BALANCE);

        vm.deal(alice, ETH_BALANCE);

        vm.startPrank(alice);

        tokenA.approve(address(router), type(uint256).max);

        tokenB.approve(address(router), type(uint256).max);

        vm.stopPrank();
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _addTokenLiquidity() internal returns (address pair, uint256 liquidity) {
        vm.prank(alice);

        (,, liquidity) = router.addLiquidity(
            address(tokenA), address(tokenB), 1_000 ether, 1_000 ether, 0, 0, alice, block.timestamp
        );

        pair = factory.getPair(address(tokenA), address(tokenB));

        assertTrue(pair != address(0));
    }

    function _addETHLiquidity() internal returns (address pair, uint256 liquidity) {
        vm.prank(alice);

        (,, liquidity) =
            router.addLiquidityETH{value: 100 ether}(address(tokenA), 1_000 ether, 0, 0, alice, block.timestamp);

        pair = factory.getPair(address(tokenA), address(weth));

        assertTrue(pair != address(0));
    }

    function _approveLP(address pair, uint256 amount) internal {
        vm.prank(alice);

        ApexV2Pair(pair).approve(address(router), amount);
    }

    // ============================================================
    // REMOVE LIQUIDITY — SUCCESS
    // ============================================================

    function test_removeLiquidity_success() public {
        (address pair, uint256 liquidity) = _addTokenLiquidity();

        uint256 liquidityToRemove = liquidity / 2;

        _approveLP(pair, liquidityToRemove);

        uint256 tokenABefore = tokenA.balanceOf(alice);

        uint256 tokenBBefore = tokenB.balanceOf(alice);

        uint256 lpBefore = ApexV2Pair(pair).balanceOf(alice);

        vm.prank(alice);

        (uint256 amountA, uint256 amountB) =
            router.removeLiquidity(address(tokenA), address(tokenB), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertGt(amountA, 0);

        assertGt(amountB, 0);

        assertEq(tokenA.balanceOf(alice) - tokenABefore, amountA);

        assertEq(tokenB.balanceOf(alice) - tokenBBefore, amountB);

        assertEq(lpBefore - ApexV2Pair(pair).balanceOf(alice), liquidityToRemove);
    }

    // ============================================================
    // REMOVE LIQUIDITY — REVERSED TOKEN ORDER
    // ============================================================

    function test_removeLiquidity_reverseTokenOrder_success() public {
        (address pair, uint256 liquidity) = _addTokenLiquidity();

        uint256 liquidityToRemove = liquidity / 2;

        _approveLP(pair, liquidityToRemove);

        uint256 tokenABefore = tokenA.balanceOf(alice);

        uint256 tokenBBefore = tokenB.balanceOf(alice);

        vm.prank(alice);

        (uint256 amountB, uint256 amountA) =
            router.removeLiquidity(address(tokenB), address(tokenA), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertGt(amountA, 0);

        assertGt(amountB, 0);

        assertEq(tokenA.balanceOf(alice) - tokenABefore, amountA);

        assertEq(tokenB.balanceOf(alice) - tokenBBefore, amountB);
    }

    // ============================================================
    // REMOVE LIQUIDITY — A_MIN
    // ============================================================

    function test_removeLiquidity_revertsWhenAMinTooHigh() public {
        (address pair, uint256 liquidity) = _addTokenLiquidity();

        _approveLP(pair, liquidity);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: A_LOW"));

        router.removeLiquidity(
            address(tokenA), address(tokenB), liquidity, type(uint256).max, 0, alice, block.timestamp
        );
    }

    // ============================================================
    // REMOVE LIQUIDITY — B_MIN
    // ============================================================

    function test_removeLiquidity_revertsWhenBMinTooHigh() public {
        (address pair, uint256 liquidity) = _addTokenLiquidity();

        _approveLP(pair, liquidity);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: B_LOW"));

        router.removeLiquidity(
            address(tokenA), address(tokenB), liquidity, 0, type(uint256).max, alice, block.timestamp
        );
    }

    // ============================================================
    // REMOVE LIQUIDITY — ZERO LIQUIDITY
    // ============================================================

    function test_removeLiquidity_revertsZeroLiquidity() public {
        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: LIQUIDITY_ZERO"));

        router.removeLiquidity(address(tokenA), address(tokenB), 0, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY — ZERO RECIPIENT
    // ============================================================

    function test_removeLiquidity_revertsZeroRecipient() public {
        (address pair, uint256 liquidity) = _addTokenLiquidity();

        _approveLP(pair, liquidity);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_RECIPIENT"));

        router.removeLiquidity(address(tokenA), address(tokenB), liquidity, 0, 0, address(0), block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY — EXPIRED
    // ============================================================

    function test_removeLiquidity_revertsExpiredDeadline() public {
        vm.warp(1000);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: EXPIRED"));

        router.removeLiquidity(address(tokenA), address(tokenB), 1 ether, 0, 0, alice, 999);
    }

    // ============================================================
    // REMOVE LIQUIDITY — IDENTICAL TOKENS
    // ============================================================

    function test_removeLiquidity_revertsIdenticalTokens() public {
        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: IDENTICAL_TOKEN"));

        router.removeLiquidity(address(tokenA), address(tokenA), 1 ether, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY — ZERO TOKEN
    // ============================================================

    function test_removeLiquidity_revertsZeroToken() public {
        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_ADDRESS"));

        router.removeLiquidity(address(0), address(tokenB), 1 ether, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY — MISSING PAIR
    // ============================================================

    function test_removeLiquidity_revertsMissingPair() public {
        vm.prank(alice);

        vm.expectRevert(bytes("PAIR_NOT_FOUND"));

        router.removeLiquidity(address(tokenA), address(tokenB), 1 ether, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY — NO LP APPROVAL
    // ============================================================

    function test_removeLiquidity_revertsWithoutLPApproval() public {
        (, uint256 liquidity) = _addTokenLiquidity();

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: TRANSFER_FROM_FAILED"));

        router.removeLiquidity(address(tokenA), address(tokenB), liquidity / 2, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — SUCCESS
    // ============================================================

    function test_removeLiquidityETH_success() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        uint256 liquidityToRemove = liquidity / 2;

        _approveLP(pair, liquidityToRemove);

        uint256 tokenBefore = tokenA.balanceOf(alice);

        uint256 ethBefore = alice.balance;

        vm.prank(alice);

        (uint256 amountToken, uint256 amountETH) =
            router.removeLiquidityETH(address(tokenA), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertGt(amountToken, 0);

        assertGt(amountETH, 0);

        assertEq(tokenA.balanceOf(alice) - tokenBefore, amountToken);

        assertEq(alice.balance - ethBefore, amountETH);

        assertEq(tokenA.balanceOf(address(router)), 0);

        assertEq(weth.balanceOf(address(router)), 0);

        assertEq(address(router).balance, 0);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — TOKEN MIN
    // ============================================================

    function test_removeLiquidityETH_revertsTokenMinTooHigh() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        _approveLP(pair, liquidity);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: A_LOW"));

        router.removeLiquidityETH(address(tokenA), liquidity, type(uint256).max, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — ETH MIN
    // ============================================================

    function test_removeLiquidityETH_revertsETHMinTooHigh() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        _approveLP(pair, liquidity);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: B_LOW"));

        router.removeLiquidityETH(address(tokenA), liquidity, 0, type(uint256).max, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — ZERO LIQUIDITY
    // ============================================================

    function test_removeLiquidityETH_revertsZeroLiquidity() public {
        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: LIQUIDITY_ZERO"));

        router.removeLiquidityETH(address(tokenA), 0, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — ZERO RECIPIENT
    // ============================================================

    function test_removeLiquidityETH_revertsZeroRecipient() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        _approveLP(pair, liquidity);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_RECIPIENT"));

        router.removeLiquidityETH(address(tokenA), liquidity, 0, 0, address(0), block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — ZERO TOKEN
    // ============================================================

    function test_removeLiquidityETH_revertsZeroToken() public {
        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_ADDRESS"));

        router.removeLiquidityETH(address(0), 1 ether, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — WETH AS TOKEN
    // ============================================================

    function test_removeLiquidityETH_revertsWETHAsToken() public {
        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: INVALID_TOKEN"));

        router.removeLiquidityETH(address(weth), 1 ether, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — EXPIRED DEADLINE
    // ============================================================

    function test_removeLiquidityETH_revertsExpiredDeadline() public {
        vm.warp(1000);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: EXPIRED"));

        router.removeLiquidityETH(address(tokenA), 1 ether, 0, 0, alice, 999);
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH — MISSING PAIR
    // ============================================================

    function test_removeLiquidityETH_revertsMissingPair() public {
        vm.prank(alice);

        vm.expectRevert(bytes("PAIR_NOT_FOUND"));

        router.removeLiquidityETH(address(tokenA), 1 ether, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // FUZZ REMOVE TOKEN LIQUIDITY
    // ============================================================

    function testFuzz_removeLiquidity_partialSuccess(uint96 rawPercent) public {
        (address pair, uint256 liquidity) = _addTokenLiquidity();

        uint256 percent = bound(uint256(rawPercent), 1, 100);

        uint256 liquidityToRemove = liquidity * percent / 100;

        if (liquidityToRemove == 0) {
            liquidityToRemove = 1;
        }

        _approveLP(pair, liquidityToRemove);

        uint256 tokenABefore = tokenA.balanceOf(alice);

        uint256 tokenBBefore = tokenB.balanceOf(alice);

        vm.prank(alice);

        (uint256 amountA, uint256 amountB) =
            router.removeLiquidity(address(tokenA), address(tokenB), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertGt(amountA, 0);

        assertGt(amountB, 0);

        assertEq(tokenA.balanceOf(alice) - tokenABefore, amountA);

        assertEq(tokenB.balanceOf(alice) - tokenBBefore, amountB);
    }

    // ============================================================
    // FUZZ REMOVE ETH LIQUIDITY
    // ============================================================

    function testFuzz_removeLiquidityETH_partialSuccess(uint96 rawPercent) public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        uint256 percent = bound(uint256(rawPercent), 1, 100);

        uint256 liquidityToRemove = liquidity * percent / 100;

        if (liquidityToRemove == 0) {
            liquidityToRemove = 1;
        }

        _approveLP(pair, liquidityToRemove);

        uint256 tokenBefore = tokenA.balanceOf(alice);

        uint256 ethBefore = alice.balance;

        vm.prank(alice);

        (uint256 amountToken, uint256 amountETH) =
            router.removeLiquidityETH(address(tokenA), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertGt(amountToken, 0);

        assertGt(amountETH, 0);

        assertEq(tokenA.balanceOf(alice) - tokenBefore, amountToken);

        assertEq(alice.balance - ethBefore, amountETH);
    }
}
