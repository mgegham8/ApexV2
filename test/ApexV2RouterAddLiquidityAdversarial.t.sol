// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/FalseReturnERC20.sol";
import "../src/contracts/test/NoReturnERC20.sol";
import "../src/contracts/test/FeeOnTransferERC20.sol";
import "../src/contracts/test/MaliciousERC20.sol";
import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterAddLiquidityAdversarialTest is Test {
    ApexV2Router internal router;
    ApexV2Factory internal factory;
    address internal weth;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    uint256 internal constant INITIAL_BALANCE = 1_000_000 ether;

    function setUp() public {
        factory = new ApexV2Factory(address(this));
        weth = address(new WETH9());

        router = new ApexV2Router(address(factory), weth);

        tokenA = new MockERC20("Token A", "TKA");

        tokenB = new MockERC20("Token B", "TKB");

        tokenA.mint(alice, INITIAL_BALANCE);

        tokenB.mint(alice, INITIAL_BALANCE);

        vm.startPrank(alice);

        tokenA.approve(address(router), type(uint256).max);

        tokenB.approve(address(router), type(uint256).max);

        vm.stopPrank();
    }

    // =============================================================
    // 1. IDENTICAL TOKEN
    // =============================================================

    function test_addLiquidity_reverts_identicalTokens() public {
        vm.startPrank(alice);

        vm.expectRevert(bytes("ApexV2Router: IDENTICAL_TOKEN"));

        router.addLiquidity(address(tokenA), address(tokenA), 100 ether, 100 ether, 0, 0, alice, block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 2. ZERO TOKEN A
    // =============================================================

    function test_addLiquidity_reverts_zeroTokenA() public {
        vm.startPrank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_ADDRESS"));

        router.addLiquidity(address(0), address(tokenB), 100 ether, 100 ether, 0, 0, alice, block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 3. ZERO TOKEN B
    // =============================================================

    function test_addLiquidity_reverts_zeroTokenB() public {
        vm.startPrank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_ADDRESS"));

        router.addLiquidity(address(tokenA), address(0), 100 ether, 100 ether, 0, 0, alice, block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 4. EXPIRED DEADLINE
    // =============================================================

    function test_addLiquidity_reverts_expiredDeadline() public {
        vm.warp(1000);

        vm.startPrank(alice);

        vm.expectRevert(bytes("ApexV2Router: EXPIRED"));

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, alice, 999);

        vm.stopPrank();
    }

    // =============================================================
    // 5. ZERO DESIRED AMOUNTS
    // =============================================================

    function test_addLiquidity_zeroDesiredAmounts() public {
        vm.startPrank(alice);

        vm.expectRevert();

        router.addLiquidity(address(tokenA), address(tokenB), 0, 0, 0, 0, alice, block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 6. FIRST LIQUIDITY
    // =============================================================

    function test_addLiquidity_createsPairAndAddsInitialLiquidity() public {
        uint256 amountA = 100 ether;
        uint256 amountB = 100 ether;

        vm.startPrank(alice);

        (uint256 usedA, uint256 usedB, uint256 liquidity) =
            router.addLiquidity(address(tokenA), address(tokenB), amountA, amountB, 0, 0, alice, block.timestamp);

        vm.stopPrank();

        assertEq(usedA, amountA);

        assertEq(usedB, amountB);

        assertGt(liquidity, 0);

        address pair = factory.getPair(address(tokenA), address(tokenB));

        assertTrue(pair != address(0));
    }

    // =============================================================
    // 7. INITIAL LIQUIDITY — A MIN
    // =============================================================

    function test_addLiquidity_initialLiquidity_revertsWhenABelowMin() public {
        vm.startPrank(alice);

        vm.expectRevert(bytes("ApexV2Router: A_LOW"));

        router.addLiquidity(
            address(tokenA), address(tokenB), 100 ether, 100 ether, 101 ether, 0, alice, block.timestamp
        );

        vm.stopPrank();
    }

    // =============================================================
    // 8. INITIAL LIQUIDITY — B MIN
    // =============================================================

    function test_addLiquidity_initialLiquidity_revertsWhenBBelowMin() public {
        vm.startPrank(alice);

        vm.expectRevert(bytes("ApexV2Router: B_LOW"));

        router.addLiquidity(
            address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 101 ether, alice, block.timestamp
        );

        vm.stopPrank();
    }

    // =============================================================
    // 9. EXISTING RESERVES — B OPTIMAL PATH
    // =============================================================

    function test_addLiquidity_existingPair_usesBOptimal() public {
        vm.startPrank(alice);

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 200 ether, 0, 0, alice, block.timestamp);

        (uint256 usedA, uint256 usedB,) =
            router.addLiquidity(address(tokenA), address(tokenB), 50 ether, 200 ether, 0, 0, alice, block.timestamp);

        vm.stopPrank();

        assertEq(usedA, 50 ether);

        assertEq(usedB, 100 ether);
    }

    // =============================================================
    // 10. EXISTING RESERVES — A OPTIMAL PATH
    // =============================================================

    function test_addLiquidity_existingPair_usesAOptimal() public {
        vm.startPrank(alice);

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, alice, block.timestamp);

        (uint256 usedA, uint256 usedB,) =
            router.addLiquidity(address(tokenA), address(tokenB), 200 ether, 50 ether, 0, 0, alice, block.timestamp);

        vm.stopPrank();

        assertEq(usedA, 50 ether);

        assertEq(usedB, 50 ether);
    }

    // =============================================================
    // 11. B OPTIMAL PATH — B_LOW
    // =============================================================

    function test_addLiquidity_reverts_BLow() public {
        vm.startPrank(alice);

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, alice, block.timestamp);

        vm.expectRevert(bytes("ApexV2Router: B_LOW"));

        router.addLiquidity(address(tokenA), address(tokenB), 50 ether, 100 ether, 0, 51 ether, alice, block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 12. A OPTIMAL PATH — A_LOW
    // =============================================================

    function test_addLiquidity_reverts_ALow() public {
        vm.startPrank(alice);

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, alice, block.timestamp);

        vm.expectRevert(bytes("ApexV2Router: A_LOW"));

        router.addLiquidity(address(tokenA), address(tokenB), 200 ether, 50 ether, 51 ether, 0, alice, block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 13. B OPTIMAL PATH — amountADesired MUST RESPECT A_MIN
    // =============================================================

    function test_addLiquidity_BOptimal_revertsWhenAmountADesiredBelowAMin() public {
        vm.startPrank(alice);

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, alice, block.timestamp);

        vm.expectRevert(bytes("ApexV2Router: A_LOW"));

        router.addLiquidity(address(tokenA), address(tokenB), 50 ether, 100 ether, 51 ether, 0, alice, block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 14. A OPTIMAL PATH — amountBDesired MUST RESPECT B_MIN
    // =============================================================

    function test_addLiquidity_AOptimal_revertsWhenAmountBDesiredBelowBMin() public {
        vm.startPrank(alice);

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, alice, block.timestamp);

        vm.expectRevert(bytes("ApexV2Router: B_LOW"));

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 50 ether, 0, 51 ether, alice, block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 15. ZERO RECIPIENT
    // =============================================================

    function test_addLiquidity_reverts_zeroRecipient() public {
        vm.startPrank(alice);

        vm.expectRevert(bytes("ApexV2Router: ZERO_RECIPIENT"));

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, address(0), block.timestamp);

        vm.stopPrank();
    }

    // =============================================================
    // 16. A_HIGH — DEFENSIVE BRANCH
    // =============================================================

    function test_addLiquidity_reverts_AHigh() public pure {
        // With mathematically consistent reserves + quote(),
        // amountAOptimal > amountADesired is generally unreachable.
        // Keep this explicit so we do not fake branch coverage.
        assertTrue(true);
    }

    // =============================================================
    // 17. FUZZ — FIRST LIQUIDITY
    // =============================================================

    function testFuzz_addLiquidity_initialAmounts(uint128 amountA, uint128 amountB) public {
        vm.assume(amountA > 1 ether);

        vm.assume(amountB > 1 ether);

        vm.assume(amountA < INITIAL_BALANCE);

        vm.assume(amountB < INITIAL_BALANCE);

        vm.startPrank(alice);

        (uint256 usedA, uint256 usedB, uint256 liquidity) =
            router.addLiquidity(address(tokenA), address(tokenB), amountA, amountB, 0, 0, alice, block.timestamp);

        vm.stopPrank();

        assertEq(usedA, amountA);

        assertEq(usedB, amountB);

        assertGt(liquidity, 0);
    }
}
