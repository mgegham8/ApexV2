// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/interfaces/IERC20.sol";

import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterFullAttackTest is Test {
    ApexV2Router router;
    ApexV2Factory factory;
    WETH9 weth;

    MockERC20 token0;
    MockERC20 token1;

    function setUp() public {
        // ==========================================
        // WETH
        // ==========================================

        weth = new WETH9();

        // ==========================================
        // FACTORY
        // ==========================================

        factory = new ApexV2Factory(address(this));

        // ==========================================
        // ROUTER
        // ==========================================

        router = new ApexV2Router(address(factory), address(weth));

        // ==========================================
        // TOKENS
        // ==========================================

        token0 = new MockERC20("T0", "T0");

        token1 = new MockERC20("T1", "T1");

        // ==========================================
        // INITIAL BALANCES
        // ==========================================

        token0.mint(address(this), 10_000 ether);

        token1.mint(address(this), 10_000 ether);
    }

    function testFullRouterAttackSimulation() public {
        uint256 initialBalance = token0.balanceOf(address(this));

        // ==========================================
        // APPROVE ROUTER
        // ==========================================

        token0.approve(address(router), type(uint256).max);

        token1.approve(address(router), type(uint256).max);

        // ==========================================
        // ADD LIQUIDITY
        // ==========================================

        router.addLiquidity(
            address(token0), address(token1), 1000 ether, 1000 ether, 0, 0, address(this), block.timestamp
        );

        // ==========================================
        // GET PAIR
        // ==========================================

        address pair = factory.getPair(address(token0), address(token1));

        assertTrue(pair != address(0), "PAIR_NOT_CREATED");

        // ==========================================
        // MANIPULATION
        // ==========================================

        token0.transfer(pair, 500 ether);

        // ==========================================
        // SWAP
        // ==========================================

        address[] memory path = new address[](2);

        path[0] = address(token0);
        path[1] = address(token1);

        router.swapExactTokensForTokens(200 ether, 0, path, address(this), block.timestamp);

        // ==========================================
        // REMOVE LIQUIDITY
        // ==========================================

        uint256 liquidity = IERC20(pair).balanceOf(address(this));

        assertGt(liquidity, 0, "NO_LIQUIDITY");

        IERC20(pair).approve(address(router), liquidity);

        router.removeLiquidity(address(token0), address(token1), liquidity, 0, 0, address(this), block.timestamp);

        // ==========================================
        // FINAL BALANCE
        // ==========================================

        uint256 finalBalance = token0.balanceOf(address(this));

        assertLe(finalBalance, initialBalance);
    }

    function testDonationIsCountedAsSwapInput() public {
        // ============================================================
        // 1. CREATE INITIAL LIQUIDITY
        // ============================================================

        token0.approve(address(router), type(uint256).max);

        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(
            address(token0), address(token1), 1000 ether, 1000 ether, 0, 0, address(this), block.timestamp
        );

        address pair = factory.getPair(address(token0), address(token1));

        assertTrue(pair != address(0), "PAIR_NOT_CREATED");

        // ============================================================
        // 2. READ RESERVES BEFORE DONATION
        // ============================================================

        (uint112 reserve0Before, uint112 reserve1Before, uint32 timestampBefore) = ApexV2Pair(pair).getReserves();

        timestampBefore; // silence warning

        assertEq(reserve0Before, 1000 ether, "BAD_INITIAL_RESERVE0");

        assertEq(reserve1Before, 1000 ether, "BAD_INITIAL_RESERVE1");

        // ============================================================
        // 3. DIRECT DONATION
        // ============================================================

        token0.transfer(pair, 500 ether);

        // IMPORTANT:
        // reserves should STILL be 1000 / 1000.
        //
        // Donation changes token balance,
        // but does NOT call sync().
        // ============================================================

        (uint112 reserve0AfterDonation, uint112 reserve1AfterDonation, uint32 timestampAfterDonation) =
            ApexV2Pair(pair).getReserves();

        timestampAfterDonation;

        assertEq(reserve0AfterDonation, 1000 ether, "DONATION_CHANGED_RESERVE0");

        assertEq(reserve1AfterDonation, 1000 ether, "DONATION_CHANGED_RESERVE1");

        // ============================================================
        // 4. CHECK ACTUAL TOKEN BALANCE
        // ============================================================

        uint256 actualBalance0 = token0.balanceOf(pair);

        uint256 actualBalance1 = token1.balanceOf(pair);

        assertEq(actualBalance0, 1500 ether, "DONATION_NOT_IN_BALANCE");

        assertEq(actualBalance1, 1000 ether, "BAD_BALANCE1");

        // ============================================================
        // 5. PERFORM SWAP
        // ============================================================

        address[] memory path = new address[](2);

        path[0] = address(token0);
        path[1] = address(token1);

        uint256 token1Before = token1.balanceOf(address(this));

        router.swapExactTokensForTokens(200 ether, 0, path, address(this), block.timestamp);

        uint256 token1After = token1.balanceOf(address(this));

        uint256 amount1Received = token1After - token1Before;

        // ============================================================
        // 6. EXPECTED RESULT
        // ============================================================

        // Because the pair sees:
        //
        // actual balance0 = 1700
        // reserve0        = 1000
        //
        // it calculates:
        //
        // amount0In = 700
        //
        // instead of only the 200 tokens sent by the router.
        //
        // The observed output from the current implementation is:
        //
        // 166.249791562447890611 T1
        // ============================================================

        assertEq(amount1Received, 166249791562447890611, "UNEXPECTED_SWAP_OUTPUT");

        // ============================================================
        // 7. CHECK FINAL RESERVES
        // ============================================================

        (uint112 reserve0AfterSwap, uint112 reserve1AfterSwap, uint32 timestampAfterSwap) =
            ApexV2Pair(pair).getReserves();

        timestampAfterSwap;

        assertEq(reserve0AfterSwap, 1700 ether, "BAD_FINAL_RESERVE0");

        assertEq(reserve1AfterSwap, 833750208437552109389, "BAD_FINAL_RESERVE1");
    }

    function testDonationThenSwapThenRemoveLiquidity() public {
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        // Initial liquidity
        router.addLiquidity(
            address(token0), address(token1), 1000 ether, 1000 ether, 0, 0, address(this), block.timestamp
        );

        address pair = factory.getPair(address(token0), address(token1));

        uint256 lpBefore = IERC20(pair).balanceOf(address(this));

        // Direct donation to pair
        token0.transfer(pair, 500 ether);

        // Swap after donation
        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        router.swapExactTokensForTokens(200 ether, 0, path, address(this), block.timestamp);

        // Remove all LP
        IERC20(pair).approve(address(router), lpBefore);

        (uint256 amountA, uint256 amountB) =
            router.removeLiquidity(address(token0), address(token1), lpBefore, 0, 0, address(this), block.timestamp);

        emit log_named_uint("Returned token0", amountA);
        emit log_named_uint("Returned token1", amountB);

        assertGt(amountA, 0);
        assertGt(amountB, 0);
    }

    function testDonationAttackAgainstExistingLP() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        // Give Alice liquidity
        token0.mint(alice, 1000 ether);
        token1.mint(alice, 1000 ether);

        vm.startPrank(alice);

        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(address(token0), address(token1), 1000 ether, 1000 ether, 0, 0, alice, block.timestamp);

        vm.stopPrank();

        address pair = factory.getPair(address(token0), address(token1));

        uint256 aliceLP = IERC20(pair).balanceOf(alice);

        // Give Bob attack capital
        token0.mint(bob, 1000 ether);

        vm.startPrank(bob);

        // Donation
        token0.transfer(pair, 500 ether);

        // Swap
        token0.approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        router.swapExactTokensForTokens(200 ether, 0, path, bob, block.timestamp);

        vm.stopPrank();

        // Alice removes liquidity
        vm.startPrank(alice);

        IERC20(pair).approve(address(router), aliceLP);

        (uint256 aliceToken0, uint256 aliceToken1) =
            router.removeLiquidity(address(token0), address(token1), aliceLP, 0, 0, alice, block.timestamp);

        vm.stopPrank();

        emit log_named_uint("Alice token0", aliceToken0);

        emit log_named_uint("Alice token1", aliceToken1);

        emit log_named_uint("Bob token0", token0.balanceOf(bob));

        emit log_named_uint("Bob token1", token1.balanceOf(bob));

        assertGt(aliceToken0, 0);
        assertGt(aliceToken1, 0);
    }

    function testDonationSyncThenSwapThenRemoveLiquidity() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        // Alice gets initial liquidity
        token0.mint(alice, 1000 ether);
        token1.mint(alice, 1000 ether);

        vm.startPrank(alice);

        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(address(token0), address(token1), 1000 ether, 1000 ether, 0, 0, alice, block.timestamp + 1);

        vm.stopPrank();

        address pairAddress = factory.getPair(address(token0), address(token1));

        ApexV2Pair pair = ApexV2Pair(pairAddress);

        uint256 aliceLP = pair.balanceOf(alice);

        // Bob gets tokens
        token0.mint(bob, 1000 ether);
        token1.mint(bob, 1000 ether);

        // Bob donates 500 token0 directly to pair
        vm.startPrank(bob);

        token0.transfer(address(pair), 500 ether);

        // Force reserves to recognize the donation
        pair.sync();

        // Bob approves router
        token0.approve(address(router), type(uint256).max);

        // Build swap path
        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        // Swap 200 token0
        router.swapExactTokensForTokens(200 ether, 0, path, bob, block.timestamp + 1);
        // Alice removes all liquidity
        vm.startPrank(alice);

        pair.approve(address(router), aliceLP);

        (uint256 amount0, uint256 amount1) =
            router.removeLiquidity(address(token0), address(token1), aliceLP, 0, 0, alice, block.timestamp + 1);

        vm.stopPrank();

        emit log_named_uint("Alice token0", amount0);
        emit log_named_uint("Alice token1", amount1);
        emit log_named_uint("Bob token0", token0.balanceOf(bob));
        emit log_named_uint("Bob token1", token1.balanceOf(bob));

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        emit log_named_uint("Final reserve0", reserve0);
        emit log_named_uint("Final reserve1", reserve1);
    }

    function testDonationAttackNetProfit() public {
        address alice = address(0xA11cE);
        address bob = address(0xB0b);

        token0.mint(alice, 1000 ether);
        token1.mint(alice, 1000 ether);

        vm.startPrank(alice);

        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(address(token0), address(token1), 1000 ether, 1000 ether, 0, 0, alice, block.timestamp + 1);

        vm.stopPrank();

        ApexV2Pair pair = ApexV2Pair(factory.getPair(address(token0), address(token1)));

        token0.mint(bob, 1000 ether);
        token1.mint(bob, 1000 ether);

        uint256 bobToken0Before = token0.balanceOf(bob);
        uint256 bobToken1Before = token1.balanceOf(bob);

        vm.startPrank(bob);

        token0.transfer(address(pair), 500 ether);

        pair.sync();

        token0.approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        router.swapExactTokensForTokens(200 ether, 0, path, bob, block.timestamp + 1);

        vm.stopPrank();

        vm.startPrank(alice);

        uint256 aliceLP = pair.balanceOf(alice);

        pair.approve(address(router), aliceLP);

        router.removeLiquidity(address(token0), address(token1), aliceLP, 0, 0, alice, block.timestamp + 1);

        vm.stopPrank();

        uint256 bobToken0After = token0.balanceOf(bob);
        uint256 bobToken1After = token1.balanceOf(bob);

        console.log("Bob token0 before:", bobToken0Before);
        console.log("Bob token1 before:", bobToken1Before);

        console.log("Bob token0 after:", bobToken0After);
        console.log("Bob token1 after:", bobToken1After);

        uint256 token0Spent = bobToken0Before - bobToken0After;
        uint256 token1Gained = bobToken1After - bobToken1Before;

        console.log("Bob token0 spent:", token0Spent);
        console.log("Bob token1 gained:", token1Gained);

        assertEq(token0Spent, 700 ether);
        assertGt(token1Gained, 0);

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        console.log("Final reserve0:", reserve0);
        console.log("Final reserve1:", reserve1);
    }

    function testDonationAttackEconomicProfit() public {
        address alice = address(0xA11cE);
        address bob = address(0xB0b);

        // -------------------------------------------------
        // 1. Alice creates initial liquidity
        // -------------------------------------------------

        token0.mint(alice, 1000 ether);
        token1.mint(alice, 1000 ether);

        vm.startPrank(alice);

        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(address(token0), address(token1), 1000 ether, 1000 ether, 0, 0, alice, block.timestamp + 1);

        vm.stopPrank();

        // Get actual pair
        ApexV2Pair pair = ApexV2Pair(factory.getPair(address(token0), address(token1)));

        // -------------------------------------------------
        // 2. Bob receives tokens
        // -------------------------------------------------

        token0.mint(bob, 1000 ether);
        token1.mint(bob, 1000 ether);

        uint256 bobToken0Before = token0.balanceOf(bob);
        uint256 bobToken1Before = token1.balanceOf(bob);

        // -------------------------------------------------
        // 3. Bob donates 500 token0
        // -------------------------------------------------

        vm.startPrank(bob);

        token0.transfer(address(pair), 500 ether);

        pair.sync();

        // -------------------------------------------------
        // 4. Bob swaps 200 token0
        // -------------------------------------------------

        token0.approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        router.swapExactTokensForTokens(200 ether, 0, path, bob, block.timestamp + 1);

        vm.stopPrank();

        // -------------------------------------------------
        // 5. Bob final balances
        // -------------------------------------------------

        uint256 bobToken0After = token0.balanceOf(bob);
        uint256 bobToken1After = token1.balanceOf(bob);

        // -------------------------------------------------
        // 6. Calculate changes
        // -------------------------------------------------

        uint256 token0Spent = bobToken0Before - bobToken0After;

        uint256 token1Gained = bobToken1After - bobToken1Before;

        console.log("========== ECONOMIC TEST ==========");
        console.log("Bob token0 before:", bobToken0Before);
        console.log("Bob token1 before:", bobToken1Before);

        console.log("Bob token0 after:", bobToken0After);
        console.log("Bob token1 after:", bobToken1After);

        console.log("Token0 spent:", token0Spent);
        console.log("Token1 gained:", token1Gained);

        // -------------------------------------------------
        // 7. Check donation + swap accounting
        // -------------------------------------------------

        assertEq(token0Spent, 700 ether);

        assertGt(token1Gained, 0);

        // -------------------------------------------------
        // 8. Calculate Bob's mark-to-market value
        //
        // Initial pool price = 1 token0 = 1 token1
        //
        // Therefore we can compare:
        //
        // initial value = token0 + token1
        // final value   = token0 + token1
        //
        // This is NOT a perfect oracle-based valuation,
        // but it gives us the first economic sanity check.
        // -------------------------------------------------

        uint256 bobInitialValue = bobToken0Before + bobToken1Before;

        uint256 bobFinalValue = bobToken0After + bobToken1After;

        console.log("Bob initial value:", bobInitialValue);
        console.log("Bob final value:", bobFinalValue);

        // -------------------------------------------------
        // 9. Calculate economic result
        // -------------------------------------------------

        if (bobFinalValue > bobInitialValue) {
            console.log("RESULT: Bob appears economically profitable");

            console.log("Profit:", bobFinalValue - bobInitialValue);
        } else {
            console.log("RESULT: Bob is NOT economically profitable");

            console.log("Loss:", bobInitialValue - bobFinalValue);
        }

        // -------------------------------------------------
        // 10. Pool reserves after attack
        // -------------------------------------------------

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);

        // -------------------------------------------------
        // 11. Invariant
        // -------------------------------------------------

        uint256 k = uint256(reserve0) * uint256(reserve1);

        console.log("Final K:", k);

        assertGt(k, 0);
    }

    function testDonationAttackEconomicProfitFuzz(uint256 donationAmount, uint256 swapAmount) public {
        address alice = address(0xA11cE);
        address bob = address(0xB0b);

        // -------------------------------------------------
        // Bounds
        // -------------------------------------------------

        donationAmount = bound(donationAmount, 1 ether, 900 ether);
        swapAmount = bound(swapAmount, 1 ether, 100 ether);

        // Bob must be able to pay donation + swap
        vm.assume(donationAmount + swapAmount <= 1000 ether);

        // -------------------------------------------------
        // 1. Alice creates initial liquidity
        // -------------------------------------------------

        token0.mint(alice, 1000 ether);
        token1.mint(alice, 1000 ether);

        vm.startPrank(alice);

        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(address(token0), address(token1), 1000 ether, 1000 ether, 0, 0, alice, block.timestamp + 1);

        vm.stopPrank();

        ApexV2Pair pair = ApexV2Pair(factory.getPair(address(token0), address(token1)));

        // -------------------------------------------------
        // 2. Bob gets initial capital
        // -------------------------------------------------

        token0.mint(bob, 1000 ether);
        token1.mint(bob, 1000 ether);

        uint256 initialToken0 = token0.balanceOf(bob);
        uint256 initialToken1 = token1.balanceOf(bob);

        // -------------------------------------------------
        // 3. Donation
        // -------------------------------------------------

        vm.startPrank(bob);

        token0.transfer(address(pair), donationAmount);

        pair.sync();

        // -------------------------------------------------
        // 4. Swap
        // -------------------------------------------------

        token0.approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        router.swapExactTokensForTokens(swapAmount, 0, path, bob, block.timestamp + 1);

        vm.stopPrank();

        // -------------------------------------------------
        // 5. Final balances
        // -------------------------------------------------

        uint256 finalToken0 = token0.balanceOf(bob);
        uint256 finalToken1 = token1.balanceOf(bob);

        uint256 token0Spent = initialToken0 - finalToken0;

        uint256 token1Gained = finalToken1 - initialToken1;

        // -------------------------------------------------
        // 6. Economic value
        //
        // Both mock tokens are treated as 1:1.
        // -------------------------------------------------

        uint256 initialValue = initialToken0 + initialToken1;

        uint256 finalValue = finalToken0 + finalToken1;

        console.log("========== DONATION FUZZ ==========");
        console.log("Donation:", donationAmount);
        console.log("Swap:", swapAmount);

        console.log("Token0 spent:", token0Spent);
        console.log("Token1 gained:", token1Gained);

        console.log("Initial value:", initialValue);
        console.log("Final value:", finalValue);

        // -------------------------------------------------
        // 7. CRITICAL SECURITY ASSERTION
        //
        // Donation + swap must NOT create economic profit.
        // -------------------------------------------------

        assertLe(finalValue, initialValue, "Donation attack produced economic profit");

        // -------------------------------------------------
        // 8. Invariant sanity check
        // -------------------------------------------------

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        uint256 k = uint256(reserve0) * uint256(reserve1);

        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        console.log("K:", k);

        assertGt(reserve0, 0);
        assertGt(reserve1, 0);
    }
}
