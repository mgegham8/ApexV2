// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";

import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/WETH9.sol";

// ============================================================================
// ETH RECIPIENTS
// ============================================================================

contract RejectETHRecipient {
    receive() external payable {
        revert("RejectETHRecipient: NO_ETH");
    }
}

contract AcceptETHRecipient {
    uint256 public totalReceived;

    receive() external payable {
        totalReceived += msg.value;
    }
}

// ============================================================================
// FINAL ROUTER EDGE SECURITY TESTS
// ============================================================================

contract ApexV2RouterFinalEdgeSecurityTest is Test {
    ApexV2Factory internal factory;
    ApexV2Router internal router;
    WETH9 internal weth;

    MockERC20 internal token;

    address internal alice = address(0xA11CE);

    uint256 internal constant TOKEN_BALANCE = 1_000_000 ether;
    uint256 internal constant ETH_BALANCE = 10_000 ether;

    function setUp() public {
        weth = new WETH9();

        factory = new ApexV2Factory(address(this));

        router = new ApexV2Router(address(factory), address(weth));

        token = new MockERC20("Token", "TKN");

        token.mint(alice, TOKEN_BALANCE);

        vm.deal(alice, ETH_BALANCE);

        vm.prank(alice);

        token.approve(address(router), type(uint256).max);
    }

    // ========================================================================
    // HELPERS
    // ========================================================================

    function _addETHLiquidity() internal returns (address pair, uint256 liquidity) {
        vm.prank(alice);

        (,, liquidity) =
            router.addLiquidityETH{value: 100 ether}(address(token), 1_000 ether, 0, 0, alice, block.timestamp);

        pair = factory.getPair(address(token), address(weth));

        assertTrue(pair != address(0), "pair not created");

        assertGt(liquidity, 0, "zero liquidity");
    }

    function _approveLP(address pair, uint256 amount) internal {
        vm.prank(alice);

        ApexV2Pair(pair).approve(address(router), amount);
    }

    function _seedSwapPool() internal returns (address pair) {
        (pair,) = _addETHLiquidity();
    }

    // ========================================================================
    // 1. REMOVE LIQUIDITY ETH -> CONTRACT RECIPIENT SUCCESS
    // ========================================================================

    function test_removeLiquidityETH_contractRecipient_success() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        AcceptETHRecipient recipient = new AcceptETHRecipient();

        uint256 liquidityToRemove = liquidity / 2;

        _approveLP(pair, liquidityToRemove);

        uint256 tokenBefore = token.balanceOf(address(recipient));

        uint256 ethBefore = address(recipient).balance;

        vm.prank(alice);

        (uint256 amountToken, uint256 amountETH) =
            router.removeLiquidityETH(address(token), liquidityToRemove, 0, 0, address(recipient), block.timestamp);

        assertGt(amountToken, 0);

        assertGt(amountETH, 0);

        assertEq(token.balanceOf(address(recipient)) - tokenBefore, amountToken);

        assertEq(address(recipient).balance - ethBefore, amountETH);

        assertEq(recipient.totalReceived(), amountETH);

        assertEq(address(router).balance, 0);

        assertEq(weth.balanceOf(address(router)), 0);
    }

    // ========================================================================
    // 2. REMOVE LIQUIDITY ETH -> RECIPIENT REJECTS ETH
    //    Entire operation must revert atomically.
    // ========================================================================

    function test_removeLiquidityETH_revertsWhenRecipientRejectsETH() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        RejectETHRecipient recipient = new RejectETHRecipient();

        uint256 liquidityToRemove = liquidity / 2;

        _approveLP(pair, liquidityToRemove);

        uint256 aliceLPBefore = ApexV2Pair(pair).balanceOf(alice);

        uint256 pairLPBefore = ApexV2Pair(pair).balanceOf(pair);

        uint256 aliceTokenBefore = token.balanceOf(alice);

        uint256 pairTokenBefore = token.balanceOf(pair);

        uint256 pairWETHBefore = weth.balanceOf(pair);

        (uint112 reserve0Before, uint112 reserve1Before,) = ApexV2Pair(pair).getReserves();

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: ETH_TRANSFER_FAILED"));

        router.removeLiquidityETH(address(token), liquidityToRemove, 0, 0, address(recipient), block.timestamp);

        // Transaction must be fully atomic.

        assertEq(ApexV2Pair(pair).balanceOf(alice), aliceLPBefore);

        assertEq(ApexV2Pair(pair).balanceOf(pair), pairLPBefore);

        assertEq(token.balanceOf(alice), aliceTokenBefore);

        assertEq(token.balanceOf(pair), pairTokenBefore);

        assertEq(weth.balanceOf(pair), pairWETHBefore);

        (uint112 reserve0After, uint112 reserve1After,) = ApexV2Pair(pair).getReserves();

        assertEq(reserve0After, reserve0Before);

        assertEq(reserve1After, reserve1Before);

        assertEq(address(router).balance, 0);

        assertEq(weth.balanceOf(address(router)), 0);
    }

    // ========================================================================
    // 3. LP ALLOWANCE EXACT BOUNDARY
    // ========================================================================

    function test_removeLiquidity_exactLPAllowance_success() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        uint256 liquidityToRemove = liquidity / 2;

        _approveLP(pair, liquidityToRemove);

        assertEq(ApexV2Pair(pair).allowance(alice, address(router)), liquidityToRemove);

        vm.prank(alice);

        router.removeLiquidityETH(address(token), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertEq(ApexV2Pair(pair).allowance(alice, address(router)), 0);
    }

    // ========================================================================
    // 4. LP ALLOWANCE ONE WEI TOO LOW
    // ========================================================================

    function test_removeLiquidity_revertsWhenLPAllowanceOneWeiTooLow() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        uint256 liquidityToRemove = liquidity / 2;

        assertGt(liquidityToRemove, 1);

        _approveLP(pair, liquidityToRemove - 1);

        uint256 lpBefore = ApexV2Pair(pair).balanceOf(alice);

        vm.prank(alice);

        vm.expectRevert();

        router.removeLiquidityETH(address(token), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertEq(ApexV2Pair(pair).balanceOf(alice), lpBefore);
    }

    // ========================================================================
    // 5. EXACT FULL LP BALANCE
    // ========================================================================

    function test_removeLiquidity_fullLPBalance_success() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        uint256 lpBalance = ApexV2Pair(pair).balanceOf(alice);

        assertEq(lpBalance, liquidity);

        _approveLP(pair, lpBalance);

        vm.prank(alice);

        (uint256 amountToken, uint256 amountETH) =
            router.removeLiquidityETH(address(token), lpBalance, 0, 0, alice, block.timestamp);

        assertGt(amountToken, 0);

        assertGt(amountETH, 0);

        assertEq(ApexV2Pair(pair).balanceOf(alice), 0);
    }

    // ========================================================================
    // 6. LP BALANCE + 1 MUST REVERT
    // ========================================================================

    function test_removeLiquidity_revertsWhenLiquidityExceedsLPBalance() public {
        (address pair,) = _addETHLiquidity();

        uint256 lpBalance = ApexV2Pair(pair).balanceOf(alice);

        uint256 requested = lpBalance + 1;

        _approveLP(pair, requested);

        uint256 lpBefore = ApexV2Pair(pair).balanceOf(alice);

        vm.prank(alice);

        vm.expectRevert();

        router.removeLiquidityETH(address(token), requested, 0, 0, alice, block.timestamp);

        assertEq(ApexV2Pair(pair).balanceOf(alice), lpBefore);
    }

    // ========================================================================
    // 7. TOKEN -> ETH SWAP TO CONTRACT RECIPIENT
    // ========================================================================

    function test_swapExactTokensForETH_contractRecipient_success() public {
        _seedSwapPool();

        AcceptETHRecipient recipient = new AcceptETHRecipient();

        address[] memory path = new address[](2);

        path[0] = address(token);
        path[1] = address(weth);

        uint256 amountIn = 10 ether;

        uint256 recipientETHBefore = address(recipient).balance;

        uint256 aliceTokenBefore = token.balanceOf(alice);

        vm.prank(alice);

        uint256[] memory amounts = router.swapExactTokensForETH(amountIn, 0, path, address(recipient), block.timestamp);

        uint256 amountETH = amounts[amounts.length - 1];

        assertGt(amountETH, 0);

        assertEq(aliceTokenBefore - token.balanceOf(alice), amountIn);

        assertEq(address(recipient).balance - recipientETHBefore, amountETH);

        assertEq(recipient.totalReceived(), amountETH);

        assertEq(address(router).balance, 0);

        assertEq(weth.balanceOf(address(router)), 0);
    }

    // ========================================================================
    // 8. TOKEN -> ETH SWAP / RECIPIENT REJECTS ETH
    // ========================================================================

    function test_swapExactTokensForETH_revertsWhenRecipientRejectsETH() public {
        address pair = _seedSwapPool();

        RejectETHRecipient recipient = new RejectETHRecipient();

        address[] memory path = new address[](2);

        path[0] = address(token);
        path[1] = address(weth);

        uint256 amountIn = 10 ether;

        uint256 aliceTokenBefore = token.balanceOf(alice);

        uint256 pairTokenBefore = token.balanceOf(pair);

        uint256 pairWETHBefore = weth.balanceOf(pair);

        (uint112 reserve0Before, uint112 reserve1Before,) = ApexV2Pair(pair).getReserves();

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: ETH_TRANSFER_FAILED"));

        router.swapExactTokensForETH(amountIn, 0, path, address(recipient), block.timestamp);

        // Input transfer and Pair.swap() must also roll back.

        assertEq(token.balanceOf(alice), aliceTokenBefore);

        assertEq(token.balanceOf(pair), pairTokenBefore);

        assertEq(weth.balanceOf(pair), pairWETHBefore);

        (uint112 reserve0After, uint112 reserve1After,) = ApexV2Pair(pair).getReserves();

        assertEq(reserve0After, reserve0Before);

        assertEq(reserve1After, reserve1Before);

        assertEq(address(router).balance, 0);

        assertEq(weth.balanceOf(address(router)), 0);
    }

    // ========================================================================
    // 9. REMOVE LIQUIDITY ETH — ROUTER MUST NOT RETAIN TOKEN DUST
    // ========================================================================

    function test_removeLiquidityETH_routerRetainsNoTokenOrETHDust() public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        uint256 liquidityToRemove = liquidity / 3;

        _approveLP(pair, liquidityToRemove);

        vm.prank(alice);

        router.removeLiquidityETH(address(token), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertEq(token.balanceOf(address(router)), 0, "router retained token");

        assertEq(weth.balanceOf(address(router)), 0, "router retained WETH");

        assertEq(address(router).balance, 0, "router retained ETH");
    }

    // ========================================================================
    // 10. TOKEN -> ETH SWAP — PREEXISTING ROUTER WETH MUST NOT BE STOLEN
    // ========================================================================

    function test_swapExactTokensForETH_doesNotUsePreexistingRouterWETH() public {
        _seedSwapPool();

        address[] memory path = new address[](2);

        path[0] = address(token);
        path[1] = address(weth);

        // Give this test contract WETH.
        weth.deposit{value: 5 ether}();

        // Send unrelated WETH to Router.
        weth.transfer(address(router), 5 ether);

        uint256 routerWETHBefore = weth.balanceOf(address(router));

        assertEq(routerWETHBefore, 5 ether);

        uint256 aliceETHBefore = alice.balance;

        vm.prank(alice);

        uint256[] memory amounts = router.swapExactTokensForETH(10 ether, 0, path, alice, block.timestamp);

        uint256 expectedETH = amounts[amounts.length - 1];

        assertEq(alice.balance - aliceETHBefore, expectedETH);

        // Critical property:
        // unrelated Router WETH must remain untouched.
        assertEq(weth.balanceOf(address(router)), routerWETHBefore);
    }

    // ========================================================================
    // 11. FUZZ LP ALLOWANCE BOUNDARY
    // ========================================================================

    function testFuzz_removeLiquidityETH_exactAllowance(uint96 rawPercent) public {
        (address pair, uint256 liquidity) = _addETHLiquidity();

        uint256 percent = bound(uint256(rawPercent), 1, 100);

        uint256 liquidityToRemove = liquidity * percent / 100;

        if (liquidityToRemove == 0) {
            liquidityToRemove = 1;
        }

        _approveLP(pair, liquidityToRemove);

        vm.prank(alice);

        (uint256 amountToken, uint256 amountETH) =
            router.removeLiquidityETH(address(token), liquidityToRemove, 0, 0, alice, block.timestamp);

        assertGt(amountToken, 0);

        assertGt(amountETH, 0);
    }
}
