// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/libraries/ApexV2Library.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2LibraryHarness {
    function sortTokens(
        address tokenA,
        address tokenB
    )
        external
        pure
        returns (
            address token0,
            address token1
        )
    {
        return ApexV2Library.sortTokens(
            tokenA,
            tokenB
        );
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    )
        external
        view
        returns (address pair)
    {
        return ApexV2Library.pairFor(
            factory,
            tokenA,
            tokenB
        );
    }

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        external
        view
        returns (
            uint256 reserveA,
            uint256 reserveB
        )
    {
        return ApexV2Library.getReserves(
            factory,
            tokenA,
            tokenB
        );
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    )
        external
        pure
        returns (uint256 amountB)
    {
        return ApexV2Library.quote(
            amountA,
            reserveA,
            reserveB
        );
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        external
        pure
        returns (uint256 amountOut)
    {
        return ApexV2Library.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
    }

    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    )
        external
        view
        returns (uint256[] memory amounts)
    {
        return ApexV2Library.getAmountsOut(
            factory,
            amountIn,
            path
        );
    }

    function getAmountsForLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB
        )
    {
        return ApexV2Library.getAmountsForLiquidity(
            factory,
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired
        );
    }
}

contract ApexV2LibraryFinalSecurityTest is Test {
    ApexV2Factory internal factory;
    ApexV2LibraryHarness internal harness;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    MockERC20 internal tokenC;

    address internal constant SETTER = address(0xA11CE);

    function setUp() public {
        factory = new ApexV2Factory(
            SETTER
        );

        harness =
            new ApexV2LibraryHarness();

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
    }

    function _createPair(
        MockERC20 first,
        MockERC20 second
    )
        internal
        returns (ApexV2Pair pair)
    {
        pair = ApexV2Pair(
            factory.createPair(
                address(first),
                address(second)
            )
        );
    }

    function _seedPair(
        MockERC20 first,
        MockERC20 second,
        uint256 amountFirst,
        uint256 amountSecond
    )
        internal
        returns (ApexV2Pair pair)
    {
        pair =
            _createPair(
                first,
                second
            );

        first.mint(
            address(this),
            amountFirst
        );

        second.mint(
            address(this),
            amountSecond
        );

        assertTrue(
            first.transfer(
                address(pair),
                amountFirst
            )
        );

        assertTrue(
            second.transfer(
                address(pair),
                amountSecond
            )
        );

        pair.mint(
            address(this)
        );
    }

    // ============================================================
    // SORT TOKENS
    // ============================================================

    function test_sortTokens_forwardOrder()
        public
        view
    {
        (
            address token0,
            address token1
        ) =
            harness.sortTokens(
                address(tokenA),
                address(tokenB)
            );

        assertLt(
            uint160(token0),
            uint160(token1)
        );

        assertTrue(
            token0 == address(tokenA) ||
                token0 == address(tokenB)
        );

        assertTrue(
            token1 == address(tokenA) ||
                token1 == address(tokenB)
        );
    }

    function test_sortTokens_reverseOrder()
        public
        view
    {
        (
            address first0,
            address first1
        ) =
            harness.sortTokens(
                address(tokenA),
                address(tokenB)
            );

        (
            address second0,
            address second1
        ) =
            harness.sortTokens(
                address(tokenB),
                address(tokenA)
            );

        assertEq(
            first0,
            second0
        );

        assertEq(
            first1,
            second1
        );
    }

    function test_sortTokens_revertsIdentical()
        public
    {
        vm.expectRevert(
            bytes(
                "IDENTICAL_ADDRESSES"
            )
        );

        harness.sortTokens(
            address(tokenA),
            address(tokenA)
        );
    }

    function test_sortTokens_revertsZeroTokenA()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_ADDRESS"
            )
        );

        harness.sortTokens(
            address(0),
            address(tokenB)
        );
    }

    function test_sortTokens_revertsZeroTokenB()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_ADDRESS"
            )
        );

        harness.sortTokens(
            address(tokenA),
            address(0)
        );
    }

    // ============================================================
    // PAIR FOR
    // ============================================================

    function test_pairFor_success()
        public
    {
        ApexV2Pair pair =
            _createPair(
                tokenA,
                tokenB
            );

        address resolved =
            harness.pairFor(
                address(factory),
                address(tokenA),
                address(tokenB)
            );

        assertEq(
            resolved,
            address(pair)
        );
    }

    function test_pairFor_reverseOrder_success()
        public
    {
        ApexV2Pair pair =
            _createPair(
                tokenA,
                tokenB
            );

        address resolved =
            harness.pairFor(
                address(factory),
                address(tokenB),
                address(tokenA)
            );

        assertEq(
            resolved,
            address(pair)
        );
    }

    function test_pairFor_revertsZeroFactory()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_FACTORY"
            )
        );

        harness.pairFor(
            address(0),
            address(tokenA),
            address(tokenB)
        );
    }

    function test_pairFor_revertsMissingPair()
        public
    {
        vm.expectRevert(
            bytes(
                "PAIR_NOT_FOUND"
            )
        );

        harness.pairFor(
            address(factory),
            address(tokenA),
            address(tokenB)
        );
    }

    function test_pairFor_revertsIdenticalTokens()
        public
    {
        vm.expectRevert(
            bytes(
                "IDENTICAL_ADDRESSES"
            )
        );

        harness.pairFor(
            address(factory),
            address(tokenA),
            address(tokenA)
        );
    }

    function test_pairFor_revertsZeroToken()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_ADDRESS"
            )
        );

        harness.pairFor(
            address(factory),
            address(tokenA),
            address(0)
        );
    }

    // ============================================================
    // GET RESERVES
    // ============================================================

    function test_getReserves_forwardOrder()
        public
    {
        _seedPair(
            tokenA,
            tokenB,
            100 ether,
            250 ether
        );

        (
            uint256 reserveA,
            uint256 reserveB
        ) =
            harness.getReserves(
                address(factory),
                address(tokenA),
                address(tokenB)
            );

        assertEq(
            reserveA,
            100 ether
        );

        assertEq(
            reserveB,
            250 ether
        );
    }

    function test_getReserves_reverseOrder()
        public
    {
        _seedPair(
            tokenA,
            tokenB,
            100 ether,
            250 ether
        );

        (
            uint256 reserveB,
            uint256 reserveA
        ) =
            harness.getReserves(
                address(factory),
                address(tokenB),
                address(tokenA)
            );

        assertEq(
            reserveA,
            100 ether
        );

        assertEq(
            reserveB,
            250 ether
        );
    }

    function test_getReserves_revertsMissingPair()
        public
    {
        vm.expectRevert(
            bytes(
                "PAIR_NOT_FOUND"
            )
        );

        harness.getReserves(
            address(factory),
            address(tokenA),
            address(tokenB)
        );
    }

    // ============================================================
    // QUOTE
    // ============================================================

    function test_quote_success()
        public
        view
    {
        uint256 amountB =
            harness.quote(
                10 ether,
                100 ether,
                200 ether
            );

        assertEq(
            amountB,
            20 ether
        );
    }

    function test_quote_revertsZeroAmount()
        public
    {
        vm.expectRevert(
            bytes(
                "INSUFFICIENT_AMOUNT"
            )
        );

        harness.quote(
            0,
            100 ether,
            100 ether
        );
    }

    function test_quote_revertsZeroReserveA()
        public
    {
        vm.expectRevert(
            bytes(
                "INSUFFICIENT_LIQUIDITY"
            )
        );

        harness.quote(
            1 ether,
            0,
            100 ether
        );
    }

    function test_quote_revertsZeroReserveB()
        public
    {
        vm.expectRevert(
            bytes(
                "INSUFFICIENT_LIQUIDITY"
            )
        );

        harness.quote(
            1 ether,
            100 ether,
            0
        );
    }

    function testFuzz_quote_matchesFormula(
        uint128 amountA,
        uint128 reserveA,
        uint128 reserveB
    )
        public
        view
    {
        vm.assume(
            amountA > 0
        );

        vm.assume(
            reserveA > 0
        );

        vm.assume(
            reserveB > 0
        );

        uint256 actual =
            harness.quote(
                uint256(amountA),
                uint256(reserveA),
                uint256(reserveB)
            );

        uint256 expected =
            uint256(amountA) *
                uint256(reserveB) /
                uint256(reserveA);

        assertEq(
            actual,
            expected
        );
    }

    function testFuzz_quote_monotonicAmountA(
        uint96 amountA1,
        uint96 delta,
        uint128 reserveA,
        uint128 reserveB
    )
        public
        view
    {
        vm.assume(
            amountA1 > 0
        );

        vm.assume(
            delta > 0
        );

        vm.assume(
            reserveA > 0
        );

        vm.assume(
            reserveB > 0
        );

        uint256 amountA2 =
            uint256(amountA1) +
                uint256(delta);

        uint256 out1 =
            harness.quote(
                uint256(amountA1),
                uint256(reserveA),
                uint256(reserveB)
            );

        uint256 out2 =
            harness.quote(
                amountA2,
                uint256(reserveA),
                uint256(reserveB)
            );

        assertGe(
            out2,
            out1
        );
    }

    // ============================================================
    // GET AMOUNT OUT
    // ============================================================

    function test_getAmountOut_success()
        public
        view
    {
        uint256 amountIn =
            10 ether;

        uint256 reserveIn =
            100 ether;

        uint256 reserveOut =
            100 ether;

        uint256 amountOut =
            harness.getAmountOut(
                amountIn,
                reserveIn,
                reserveOut
            );

        uint256 amountInWithFee =
            amountIn * 997;

        uint256 numerator =
            amountInWithFee *
                reserveOut;

        uint256 denominator =
            reserveIn *
                1000 +
                amountInWithFee;

        uint256 expected =
            numerator /
                denominator;

        assertEq(
            amountOut,
            expected
        );
    }

    function test_getAmountOut_revertsZeroInput()
        public
    {
        vm.expectRevert(
            bytes(
                "INSUFFICIENT_INPUT"
            )
        );

        harness.getAmountOut(
            0,
            100 ether,
            100 ether
        );
    }

    function test_getAmountOut_revertsZeroReserveIn()
        public
    {
        vm.expectRevert(
            bytes(
                "INSUFFICIENT_LIQUIDITY"
            )
        );

        harness.getAmountOut(
            1 ether,
            0,
            100 ether
        );
    }

    function test_getAmountOut_revertsZeroReserveOut()
        public
    {
        vm.expectRevert(
            bytes(
                "INSUFFICIENT_LIQUIDITY"
            )
        );

        harness.getAmountOut(
            1 ether,
            100 ether,
            0
        );
    }

    function testFuzz_getAmountOut_lessThanReserveOut(
        uint128 amountIn,
        uint128 reserveIn,
        uint128 reserveOut
    )
        public
        view
    {
        vm.assume(
            amountIn > 0
        );

        vm.assume(
            reserveIn > 0
        );

        vm.assume(
            reserveOut > 0
        );

        uint256 a =
            uint256(amountIn);

        uint256 rIn =
            uint256(reserveIn);

        uint256 rOut =
            uint256(reserveOut);

        vm.assume(
            a <=
                type(uint256).max / 997
        );

        uint256 amountInWithFee =
            a * 997;

        vm.assume(
            rOut <=
                type(uint256).max /
                    amountInWithFee
        );

        vm.assume(
            rIn <=
                type(uint256).max / 1000
        );

        uint256 scaledReserveIn =
            rIn * 1000;

        vm.assume(
            scaledReserveIn <=
                type(uint256).max -
                    amountInWithFee
        );

        uint256 amountOut =
            harness.getAmountOut(
                a,
                rIn,
                rOut
            );

        assertLt(
            amountOut,
            rOut
        );
    }

    function testFuzz_getAmountOut_matchesFormula(
        uint128 amountIn,
        uint128 reserveIn,
        uint128 reserveOut
    )
        public
        view
    {
        vm.assume(
            amountIn > 0
        );

        vm.assume(
            reserveIn > 0
        );

        vm.assume(
            reserveOut > 0
        );

        uint256 a =
            uint256(amountIn);

        uint256 rIn =
            uint256(reserveIn);

        uint256 rOut =
            uint256(reserveOut);

        vm.assume(
            a <=
                type(uint256).max / 997
        );

        uint256 amountInWithFee =
            a * 997;

        vm.assume(
            rOut <=
                type(uint256).max /
                    amountInWithFee
        );

        vm.assume(
            rIn <=
                type(uint256).max / 1000
        );

        uint256 scaledReserveIn =
            rIn * 1000;

        vm.assume(
            scaledReserveIn <=
                type(uint256).max -
                    amountInWithFee
        );

        uint256 expected =
            (
                amountInWithFee *
                    rOut
            ) /
            (
                scaledReserveIn +
                    amountInWithFee
            );

        uint256 actual =
            harness.getAmountOut(
                a,
                rIn,
                rOut
            );

        assertEq(
            actual,
            expected
        );
    }

    function test_getAmountOut_revertsAmountOverflow()
        public
    {
        vm.expectRevert(
            bytes(
                "AMOUNT_OVERFLOW"
            )
        );

        harness.getAmountOut(
            type(uint256).max,
            1,
            1
        );
    }

    function test_getAmountOut_revertsReserveOverflow()
        public
    {
        vm.expectRevert(
            bytes(
                "RESERVE_OVERFLOW"
            )
        );

        harness.getAmountOut(
            1,
            type(uint256).max,
            1
        );
    }

    function testFuzz_getAmountOut_monotonicInput(
        uint96 amountIn1,
        uint96 delta,
        uint128 reserveIn,
        uint128 reserveOut
    )
        public
        view
    {
        vm.assume(
            amountIn1 > 0
        );

        vm.assume(
            delta > 0
        );

        vm.assume(
            reserveIn > 0
        );

        vm.assume(
            reserveOut > 0
        );

        uint256 amountIn2 =
            uint256(amountIn1) +
                uint256(delta);

        uint256 out1 =
            harness.getAmountOut(
                uint256(amountIn1),
                uint256(reserveIn),
                uint256(reserveOut)
            );

        uint256 out2 =
            harness.getAmountOut(
                amountIn2,
                uint256(reserveIn),
                uint256(reserveOut)
            );

        assertGe(
            out2,
            out1
        );
    }

    // ============================================================
    // GET AMOUNTS OUT
    // ============================================================

    function test_getAmountsOut_singleHop()
        public
    {
        _seedPair(
            tokenA,
            tokenB,
            1000 ether,
            1000 ether
        );

        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256[] memory amounts =
            harness.getAmountsOut(
                address(factory),
                10 ether,
                path
            );

        assertEq(
            amounts.length,
            2
        );

        assertEq(
            amounts[0],
            10 ether
        );

        assertGt(
            amounts[1],
            0
        );

        assertLt(
            amounts[1],
            1000 ether
        );
    }

    function test_getAmountsOut_multiHop()
        public
    {
        _seedPair(
            tokenA,
            tokenB,
            1000 ether,
            1000 ether
        );

        _seedPair(
            tokenB,
            tokenC,
            2000 ether,
            1000 ether
        );

        address[] memory path =
            new address[](3);

        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        uint256[] memory amounts =
            harness.getAmountsOut(
                address(factory),
                10 ether,
                path
            );

        assertEq(
            amounts.length,
            3
        );

        assertEq(
            amounts[0],
            10 ether
        );

        assertGt(
            amounts[1],
            0
        );

        assertGt(
            amounts[2],
            0
        );
    }

    function test_getAmountsOut_revertsZeroFactory()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.expectRevert(
            bytes(
                "ZERO_FACTORY"
            )
        );

        harness.getAmountsOut(
            address(0),
            1 ether,
            path
        );
    }

    function test_getAmountsOut_revertsZeroInput()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.expectRevert(
            bytes(
                "INSUFFICIENT_INPUT"
            )
        );

        harness.getAmountsOut(
            address(factory),
            0,
            path
        );
    }

    function test_getAmountsOut_revertsEmptyPath()
        public
    {
        address[] memory path =
            new address[](0);

        vm.expectRevert(
            bytes(
                "INVALID_PATH"
            )
        );

        harness.getAmountsOut(
            address(factory),
            1 ether,
            path
        );
    }

    function test_getAmountsOut_revertsOneTokenPath()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(tokenA);

        vm.expectRevert(
            bytes(
                "INVALID_PATH"
            )
        );

        harness.getAmountsOut(
            address(factory),
            1 ether,
            path
        );
    }

    function test_getAmountsOut_revertsDuplicateAdjacentToken()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenA);

        vm.expectRevert(
            bytes(
                "IDENTICAL_ADDRESSES"
            )
        );

        harness.getAmountsOut(
            address(factory),
            1 ether,
            path
        );
    }

    function test_getAmountsOut_revertsZeroAddressInPath()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(0);

        vm.expectRevert(
            bytes(
                "ZERO_ADDRESS"
            )
        );

        harness.getAmountsOut(
            address(factory),
            1 ether,
            path
        );
    }

    function test_getAmountsOut_revertsMissingPair()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.expectRevert(
            bytes(
                "PAIR_NOT_FOUND"
            )
        );

        harness.getAmountsOut(
            address(factory),
            1 ether,
            path
        );
    }

    // ============================================================
    // GET AMOUNTS FOR LIQUIDITY
    // ============================================================

    function test_getAmountsForLiquidity_noPairUsesDesiredAmounts()
        public
        view
    {
        (
            uint256 amountA,
            uint256 amountB
        ) =
            harness.getAmountsForLiquidity(
                address(factory),
                address(tokenA),
                address(tokenB),
                100 ether,
                200 ether
            );

        assertEq(
            amountA,
            100 ether
        );

        assertEq(
            amountB,
            200 ether
        );
    }

    function test_getAmountsForLiquidity_existingEmptyPairUsesDesiredAmounts()
        public
    {
        _createPair(
            tokenA,
            tokenB
        );

        (
            uint256 amountA,
            uint256 amountB
        ) =
            harness.getAmountsForLiquidity(
                address(factory),
                address(tokenA),
                address(tokenB),
                100 ether,
                200 ether
            );

        assertEq(
            amountA,
            100 ether
        );

        assertEq(
            amountB,
            200 ether
        );
    }

    function test_getAmountsForLiquidity_usesBOptimal()
        public
    {
        _seedPair(
            tokenA,
            tokenB,
            100 ether,
            200 ether
        );

        (
            uint256 amountA,
            uint256 amountB
        ) =
            harness.getAmountsForLiquidity(
                address(factory),
                address(tokenA),
                address(tokenB),
                50 ether,
                200 ether
            );

        assertEq(
            amountA,
            50 ether
        );

        assertEq(
            amountB,
            100 ether
        );
    }

    function test_getAmountsForLiquidity_usesAOptimal()
        public
    {
        _seedPair(
            tokenA,
            tokenB,
            100 ether,
            100 ether
        );

        (
            uint256 amountA,
            uint256 amountB
        ) =
            harness.getAmountsForLiquidity(
                address(factory),
                address(tokenA),
                address(tokenB),
                200 ether,
                50 ether
            );

        assertEq(
            amountA,
            50 ether
        );

        assertEq(
            amountB,
            50 ether
        );
    }

    function test_getAmountsForLiquidity_revertsZeroFactory()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_FACTORY"
            )
        );

        harness.getAmountsForLiquidity(
            address(0),
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether
        );
    }

    function test_getAmountsForLiquidity_revertsIdenticalTokens()
        public
    {
        vm.expectRevert(
            bytes(
                "IDENTICAL_ADDRESSES"
            )
        );

        harness.getAmountsForLiquidity(
            address(factory),
            address(tokenA),
            address(tokenA),
            100 ether,
            100 ether
        );
    }

    function test_getAmountsForLiquidity_revertsZeroToken()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_ADDRESS"
            )
        );

        harness.getAmountsForLiquidity(
            address(factory),
            address(tokenA),
            address(0),
            100 ether,
            100 ether
        );
    }

    function test_getAmountsForLiquidity_revertsZeroDesiredA()
        public
    {
        vm.expectRevert(
            bytes(
                "INSUFFICIENT_A"
            )
        );

        harness.getAmountsForLiquidity(
            address(factory),
            address(tokenA),
            address(tokenB),
            0,
            100 ether
        );
    }

    function test_getAmountsForLiquidity_revertsZeroDesiredB()
        public
    {
        vm.expectRevert(
            bytes(
                "INSUFFICIENT_B"
            )
        );

        harness.getAmountsForLiquidity(
            address(factory),
            address(tokenA),
            address(tokenB),
            100 ether,
            0
        );
    }

    function test_getAmountsForLiquidity_revertsOneSidedReserves()
        public
    {
        ApexV2Pair pair =
            _createPair(
                tokenA,
                tokenB
            );

        tokenA.mint(
            address(this),
            100 ether
        );

        assertTrue(
            tokenA.transfer(
                address(pair),
                100 ether
            )
        );

        pair.sync();

        vm.expectRevert(
            bytes(
                "INVALID_RESERVES"
            )
        );

        harness.getAmountsForLiquidity(
            address(factory),
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether
        );
    }

    // ============================================================
    // FUZZ TOKEN SORTING
    // ============================================================

    function testFuzz_sortTokens(
        address tokenX,
        address tokenY
    )
        public
        view
    {
        vm.assume(
            tokenX != address(0)
        );

        vm.assume(
            tokenY != address(0)
        );

        vm.assume(
            tokenX != tokenY
        );

        (
            address token0,
            address token1
        ) =
            harness.sortTokens(
                tokenX,
                tokenY
            );

        assertLt(
            uint160(token0),
            uint160(token1)
        );

        assertTrue(
            token0 == tokenX ||
                token0 == tokenY
        );

        assertTrue(
            token1 == tokenX ||
                token1 == tokenY
        );
    }
}