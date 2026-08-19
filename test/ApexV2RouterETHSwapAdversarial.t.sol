// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterETHSwapAdversarialTest is Test {
    ApexV2Factory internal factory;
    ApexV2Router internal router;
    WETH9 internal weth;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal alice = address(0xA11CE);

    uint256 internal constant INITIAL_TOKEN_BALANCE = 1_000_000 ether;

    uint256 internal constant INITIAL_ETH_BALANCE = 10_000 ether;

    function setUp() public {
        weth = new WETH9();

        factory = new ApexV2Factory(address(this));

        router = new ApexV2Router(address(factory), address(weth));

        tokenA = new MockERC20("Token A", "TKA");

        tokenB = new MockERC20("Token B", "TKB");

        tokenA.mint(alice, INITIAL_TOKEN_BALANCE);

        tokenB.mint(alice, INITIAL_TOKEN_BALANCE);

        vm.deal(alice, INITIAL_ETH_BALANCE);

        vm.startPrank(alice);

        tokenA.approve(address(router), type(uint256).max);

        tokenB.approve(address(router), type(uint256).max);

        vm.stopPrank();
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _addTokenAWETHLiquidity() internal {
        vm.prank(alice);

        router.addLiquidityETH{value: 100 ether}(address(tokenA), 1_000 ether, 0, 0, alice, block.timestamp);
    }

    function _addTokenBWETHLiquidity() internal {
        vm.prank(alice);

        router.addLiquidityETH{value: 100 ether}(address(tokenB), 1_000 ether, 0, 0, alice, block.timestamp);
    }

    function _addTokenATokenBLiquidity() internal {
        vm.prank(alice);

        router.addLiquidity(address(tokenA), address(tokenB), 1_000 ether, 1_000 ether, 0, 0, alice, block.timestamp);
    }

    // ============================================================
    // ETH -> TOKEN SUCCESS
    // ============================================================

    function test_swapExactETHForTokens_success() public {
        _addTokenAWETHLiquidity();

        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(tokenA);

        uint256 tokenBefore = tokenA.balanceOf(alice);

        uint256 ethBefore = alice.balance;

        vm.prank(alice);

        uint256[] memory amounts = router.swapExactETHForTokens{value: 1 ether}(0, path, alice, block.timestamp);

        uint256 tokenAfter = tokenA.balanceOf(alice);

        assertEq(amounts.length, 2);

        assertEq(amounts[0], 1 ether);

        assertGt(amounts[1], 0);

        assertEq(tokenAfter - tokenBefore, amounts[1]);

        assertEq(alice.balance, ethBefore - 1 ether);
    }

    // ============================================================
    // TOKEN -> ETH SUCCESS
    // ============================================================

    function test_swapExactTokensForETH_success() public {
        _addTokenAWETHLiquidity();

        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(weth);

        uint256 tokenBefore = tokenA.balanceOf(alice);

        uint256 ethBefore = alice.balance;

        vm.prank(alice);

        uint256[] memory amounts = router.swapExactTokensForETH(10 ether, 0, path, alice, block.timestamp);

        assertEq(amounts.length, 2);

        assertEq(amounts[0], 10 ether);

        assertGt(amounts[1], 0);

        assertEq(tokenBefore - tokenA.balanceOf(alice), 10 ether);

        assertEq(alice.balance - ethBefore, amounts[1]);
    }

    // ============================================================
    // ETH -> TOKEN ZERO INPUT
    // ============================================================

    function test_swapExactETHForTokens_revertsZeroInput() public {
        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(tokenA);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: INSUFFICIENT_INPUT"));

        router.swapExactETHForTokens(0, path, alice, block.timestamp);
    }

    // ============================================================
    // TOKEN -> ETH ZERO INPUT
    // ============================================================

    function test_swapExactTokensForETH_revertsZeroInput() public {
        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(weth);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: INSUFFICIENT_INPUT"));

        router.swapExactTokensForETH(0, 0, path, alice, block.timestamp);
    }

    // ============================================================
    // ETH -> TOKEN INVALID WETH PATH
    // ============================================================

    function test_swapExactETHForTokens_revertsWrongFirstToken() public {
        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: INVALID_WETH_PATH"));

        router.swapExactETHForTokens{value: 1 ether}(0, path, alice, block.timestamp);
    }

    // ============================================================
    // TOKEN -> ETH INVALID WETH PATH
    // ============================================================

    function test_swapExactTokensForETH_revertsWrongLastToken() public {
        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: INVALID_WETH_PATH"));

        router.swapExactTokensForETH(1 ether, 0, path, alice, block.timestamp);
    }

    // ============================================================
    // ETH -> TOKEN ZERO RECIPIENT
    // ============================================================

    function test_swapExactETHForTokens_revertsZeroRecipient() public {
        _addTokenAWETHLiquidity();

        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(tokenA);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_RECIPIENT"));

        router.swapExactETHForTokens{value: 1 ether}(0, path, address(0), block.timestamp);
    }

    // ============================================================
    // TOKEN -> ETH ZERO RECIPIENT
    // ============================================================

    function test_swapExactTokensForETH_revertsZeroRecipient() public {
        _addTokenAWETHLiquidity();

        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(weth);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_RECIPIENT"));

        router.swapExactTokensForETH(1 ether, 0, path, address(0), block.timestamp);
    }

    // ============================================================
    // ETH -> TOKEN MISSING PAIR
    // ============================================================

    function test_swapExactETHForTokens_revertsMissingPair() public {
        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(tokenA);

        vm.prank(alice);

        vm.expectRevert(bytes("PAIR_NOT_FOUND"));

        router.swapExactETHForTokens{value: 1 ether}(0, path, alice, block.timestamp);
    }

    // ============================================================
    // TOKEN -> ETH MISSING PAIR
    // ============================================================

    function test_swapExactTokensForETH_revertsMissingPair() public {
        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(weth);

        vm.prank(alice);

        vm.expectRevert(bytes("PAIR_NOT_FOUND"));

        router.swapExactTokensForETH(1 ether, 0, path, alice, block.timestamp);
    }

    // ============================================================
    // ETH -> TOKEN SLIPPAGE
    // ============================================================

    function test_swapExactETHForTokens_revertsSlippage() public {
        _addTokenAWETHLiquidity();

        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(tokenA);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: SLIPPAGE"));

        router.swapExactETHForTokens{value: 1 ether}(type(uint256).max, path, alice, block.timestamp);
    }

    // ============================================================
    // TOKEN -> ETH SLIPPAGE
    // ============================================================

    function test_swapExactTokensForETH_revertsSlippage() public {
        _addTokenAWETHLiquidity();

        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(weth);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: SLIPPAGE"));

        router.swapExactTokensForETH(10 ether, type(uint256).max, path, alice, block.timestamp);
    }

    // ============================================================
    // ETH -> TOKEN EMPTY PATH
    // ============================================================

    function test_swapExactETHForTokens_revertsEmptyPath() public {
        address[] memory path = new address[](0);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: INVALID_PATH"));

        router.swapExactETHForTokens{value: 1 ether}(0, path, alice, block.timestamp);
    }

    // ============================================================
    // TOKEN -> ETH EMPTY PATH
    // ============================================================

    function test_swapExactTokensForETH_revertsEmptyPath() public {
        address[] memory path = new address[](0);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: INVALID_PATH"));

        router.swapExactTokensForETH(1 ether, 0, path, alice, block.timestamp);
    }

    // ============================================================
    // ETH -> TOKEN DUPLICATE TOKEN
    // ============================================================

    function test_swapExactETHForTokens_revertsDuplicateToken() public {
        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(weth);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: IDENTICAL_TOKEN"));

        router.swapExactETHForTokens{value: 1 ether}(0, path, alice, block.timestamp);
    }

    // ============================================================
    // TOKEN -> ETH DUPLICATE TOKEN
    // ============================================================

    function test_swapExactTokensForETH_revertsDuplicateToken() public {
        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(weth);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: IDENTICAL_TOKEN"));

        router.swapExactTokensForETH(1 ether, 0, path, alice, block.timestamp);
    }

    // ============================================================
    // ETH -> TOKEN MULTI-HOP
    // WETH -> tokenB -> tokenA
    // ============================================================

    function test_swapExactETHForTokens_multiHopSuccess() public {
        _addTokenBWETHLiquidity();
        _addTokenATokenBLiquidity();

        address[] memory path = new address[](3);

        path[0] = address(weth);
        path[1] = address(tokenB);
        path[2] = address(tokenA);

        uint256 balanceBefore = tokenA.balanceOf(alice);

        vm.prank(alice);

        uint256[] memory amounts = router.swapExactETHForTokens{value: 1 ether}(0, path, alice, block.timestamp);

        assertEq(amounts.length, 3);

        assertEq(amounts[0], 1 ether);

        assertGt(amounts[1], 0);

        assertGt(amounts[2], 0);

        assertEq(tokenA.balanceOf(alice) - balanceBefore, amounts[2]);
    }

    // ============================================================
    // TOKEN -> ETH MULTI-HOP
    // tokenA -> tokenB -> WETH
    // ============================================================

    function test_swapExactTokensForETH_multiHopSuccess() public {
        _addTokenBWETHLiquidity();
        _addTokenATokenBLiquidity();

        address[] memory path = new address[](3);

        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(weth);

        uint256 ethBefore = alice.balance;

        vm.prank(alice);

        uint256[] memory amounts = router.swapExactTokensForETH(10 ether, 0, path, alice, block.timestamp);

        assertEq(amounts.length, 3);

        assertEq(amounts[0], 10 ether);

        assertGt(amounts[1], 0);

        assertGt(amounts[2], 0);

        assertEq(alice.balance - ethBefore, amounts[2]);
    }

    // ============================================================
    // DEADLINE ETH -> TOKEN
    // ============================================================

    function test_swapExactETHForTokens_revertsExpiredDeadline() public {
        vm.warp(1000);

        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(tokenA);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: EXPIRED"));

        router.swapExactETHForTokens{value: 1 ether}(0, path, alice, 999);
    }

    // ============================================================
    // DEADLINE TOKEN -> ETH
    // ============================================================

    function test_swapExactTokensForETH_revertsExpiredDeadline() public {
        vm.warp(1000);

        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(weth);

        vm.prank(alice);

        vm.expectRevert(bytes("ApexV2Router: EXPIRED"));

        router.swapExactTokensForETH(1 ether, 0, path, alice, 999);
    }

    // ============================================================
    // FUZZ ETH -> TOKEN
    // ============================================================

    function testFuzz_swapExactETHForTokens_success(uint96 rawAmountIn) public {
        _addTokenAWETHLiquidity();

        uint256 amountIn = bound(uint256(rawAmountIn), 1 wei, 10 ether);

        address[] memory path = new address[](2);

        path[0] = address(weth);
        path[1] = address(tokenA);

        uint256 balanceBefore = tokenA.balanceOf(alice);

        vm.prank(alice);

        uint256[] memory amounts = router.swapExactETHForTokens{value: amountIn}(0, path, alice, block.timestamp);

        assertEq(amounts[0], amountIn);

        assertGt(amounts[1], 0);

        assertEq(tokenA.balanceOf(alice) - balanceBefore, amounts[1]);
    }

    // ============================================================
    // FUZZ TOKEN -> ETH
    // ============================================================

    function testFuzz_swapExactTokensForETH_success(uint96 rawAmountIn) public {
        _addTokenAWETHLiquidity();

        uint256 amountIn = bound(uint256(rawAmountIn), 1 ether, 100 ether);

        address[] memory path = new address[](2);

        path[0] = address(tokenA);
        path[1] = address(weth);

        uint256 ethBefore = alice.balance;

        vm.prank(alice);

        uint256[] memory amounts = router.swapExactTokensForETH(amountIn, 0, path, alice, block.timestamp);

        assertEq(amounts[0], amountIn);

        assertGt(amounts[1], 0);

        assertEq(alice.balance - ethBefore, amounts[1]);
    }
}
