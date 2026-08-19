// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";

import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterBranchFinalTest is Test {
    ApexV2Factory internal factory;
    ApexV2Router internal router;
    WETH9 internal weth;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    MockERC20 internal tokenC;

    address internal constant ALICE = address(0xA11CE);

    uint256 internal constant BALANCE = 1_000_000 ether;

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

        tokenC = new MockERC20(
            "Token C",
            "TKC"
        );

        tokenA.mint(
            ALICE,
            BALANCE
        );

        tokenB.mint(
            ALICE,
            BALANCE
        );

        tokenC.mint(
            ALICE,
            BALANCE
        );

        vm.deal(
            ALICE,
            10_000 ether
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

        tokenC.approve(
            address(router),
            type(uint256).max
        );

        vm.stopPrank();
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _createPair(
        address token0,
        address token1
    )
        internal
        returns (ApexV2Pair pair)
    {
        pair = ApexV2Pair(
            factory.createPair(
                token0,
                token1
            )
        );
    }

    function _seedPair(
        MockERC20 firstToken,
        MockERC20 secondToken,
        uint256 firstAmount,
        uint256 secondAmount
    )
        internal
        returns (ApexV2Pair pair)
    {
        pair = _createPair(
            address(firstToken),
            address(secondToken)
        );

        firstToken.mint(
            address(this),
            firstAmount
        );

        secondToken.mint(
            address(this),
            secondAmount
        );

        firstToken.transfer(
            address(pair),
            firstAmount
        );

        secondToken.transfer(
            address(pair),
            secondAmount
        );

        pair.mint(
            address(this)
        );
    }

    // ============================================================
    // 1. TOKEN/TOKEN ONE-SIDED RESERVES
    //
    // reserveA > 0
    // reserveB == 0
    //
    // Router must reject the corrupted/incomplete reserve state.
    // ============================================================

    function test_addLiquidity_revertsOneSidedReserves()
        public
    {
        ApexV2Pair pair =
            _createPair(
                address(tokenA),
                address(tokenB)
            );

        tokenA.mint(
            address(this),
            100 ether
        );

        tokenA.transfer(
            address(pair),
            100 ether
        );

        pair.sync();

        (
            uint112 reserve0,
            uint112 reserve1,
        ) = pair.getReserves();

        assertTrue(
            reserve0 == 0 ||
            reserve1 == 0,
            "expected one-sided reserves"
        );

        assertTrue(
            reserve0 > 0 ||
            reserve1 > 0,
            "expected one non-zero reserve"
        );

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_RESERVES"
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
            block.timestamp
        );
    }

    // ============================================================
    // 2. TOKEN/WETH ONE-SIDED RESERVES
    //
    // reserveToken > 0
    // reserveETH == 0
    //
    // addLiquidityETH must reject.
    // ============================================================

    function test_addLiquidityETH_revertsOneSidedReserves()
        public
    {
        ApexV2Pair pair =
            _createPair(
                address(tokenA),
                address(weth)
            );

        tokenA.mint(
            address(this),
            100 ether
        );

        tokenA.transfer(
            address(pair),
            100 ether
        );

        pair.sync();

        (
            uint112 reserve0,
            uint112 reserve1,
        ) = pair.getReserves();

        assertTrue(
            reserve0 == 0 ||
            reserve1 == 0,
            "expected one-sided reserves"
        );

        assertTrue(
            reserve0 > 0 ||
            reserve1 > 0,
            "expected one non-zero reserve"
        );

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_RESERVES"
            )
        );

        router.addLiquidityETH{
            value: 10 ether
        }(
            address(tokenA),
            100 ether,
            0,
            0,
            ALICE,
            block.timestamp
        );
    }

    // ============================================================
    // 3. SINGLE-HOP ROUNDING TO ZERO OUTPUT
    //
    // Reserve configuration:
    //
    // input reserve  = 1 ether
    // output reserve = 1,000,000 raw units
    //
    // amountIn = 1 wei
    //
    // getAmountOut() rounds down to zero.
    // Router must reject ZERO_OUTPUT.
    // ============================================================

    function test_swapExactTokensForTokens_revertsZeroCalculatedOutput()
        public
    {
        ApexV2Pair pair =
            _seedPair(
                tokenA,
                tokenB,
                1 ether,
                1_000_000
            );

        assertTrue(
            address(pair) != address(0)
        );

        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_OUTPUT"
            )
        );

        router.swapExactTokensForTokens(
            1,
            0,
            path,
            ALICE,
            block.timestamp
        );
    }

    // ============================================================
    // 4. REVERSED TOKEN ORDER ZERO OUTPUT
    //
    // Same property, but the input/output addresses are deliberately
    // reversed relative to Pair token ordering where possible.
    //
    // This exercises the opposite amount0Out/amount1Out direction.
    // ============================================================

    function test_swapExactTokensForTokens_reverseDirection_revertsZeroOutput()
        public
    {
        ApexV2Pair pair =
            _createPair(
                address(tokenA),
                address(tokenB)
            );

        address pairToken0 =
            pair.token0();


        MockERC20 inputToken;
        MockERC20 outputToken;

        if (
            pairToken0 == address(tokenA)
        ) {
            inputToken = tokenB;
            outputToken = tokenA;
        } else {
            inputToken = tokenA;
            outputToken = tokenB;
        }

        inputToken.mint(
            address(this),
            1 ether
        );

        outputToken.mint(
            address(this),
            1_000_000
        );

        inputToken.transfer(
            address(pair),
            1 ether
        );

        outputToken.transfer(
            address(pair),
            1_000_000
        );

        pair.mint(
            address(this)
        );

        inputToken.mint(
            ALICE,
            100 ether
        );

        vm.prank(ALICE);

        inputToken.approve(
            address(router),
            type(uint256).max
        );

        address[] memory path =
            new address[](2);

        path[0] = address(inputToken);
        path[1] = address(outputToken);

        vm.prank(ALICE);

        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_OUTPUT"
            )
        );

        router.swapExactTokensForTokens(
            1,
            0,
            path,
            ALICE,
            block.timestamp
        );
    }
}