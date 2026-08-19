// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/libraries/ApexMath.sol";
import "../src/contracts/libraries/UQ112x112.sol";

contract ApexMathHarness {
    function min(
        uint256 x,
        uint256 y
    )
        external
        pure
        returns (uint256)
    {
        return ApexMath.min(x, y);
    }

    function sqrt(
        uint256 y
    )
        external
        pure
        returns (uint256)
    {
        return ApexMath.sqrt(y);
    }
}

contract UQ112x112Harness {
    function encode(
        uint112 y
    )
        external
        pure
        returns (uint224)
    {
        return UQ112x112.encode(y);
    }

    function uqdiv(
        uint224 x,
        uint112 y
    )
        external
        pure
        returns (uint224)
    {
        return UQ112x112.uqdiv(
            x,
            y
        );
    }
}

contract ApexV2MathFinalSecurityTest is Test {
    ApexMathHarness internal math;
    UQ112x112Harness internal uq;

    uint224 internal constant Q112 =
        uint224(1) << 112;

    function setUp()
        public
    {
        math =
            new ApexMathHarness();

        uq =
            new UQ112x112Harness();
    }

    // ============================================================
    // MIN
    // ============================================================

    function test_min_returnsXWhenXLower()
        public
        view
    {
        assertEq(
            math.min(1, 2),
            1
        );
    }

    function test_min_returnsYWhenYLower()
        public
        view
    {
        assertEq(
            math.min(2, 1),
            1
        );
    }

    function test_min_equalValues()
        public
        view
    {
        assertEq(
            math.min(100, 100),
            100
        );
    }

    function test_min_zero()
        public
        view
    {
        assertEq(
            math.min(0, 100),
            0
        );

        assertEq(
            math.min(100, 0),
            0
        );
    }

    function test_min_maxUint()
        public
        view
    {
        assertEq(
            math.min(
                type(uint256).max,
                1
            ),
            1
        );

        assertEq(
            math.min(
                type(uint256).max,
                type(uint256).max
            ),
            type(uint256).max
        );
    }

    function testFuzz_min(
        uint256 x,
        uint256 y
    )
        public
        view
    {
        uint256 result =
            math.min(
                x,
                y
            );

        assertLe(
            result,
            x
        );

        assertLe(
            result,
            y
        );

        assertTrue(
            result == x ||
            result == y
        );
    }

    // ============================================================
    // SQRT - FIXED VALUES
    // ============================================================

    function test_sqrt_zero()
        public
        view
    {
        assertEq(
            math.sqrt(0),
            0
        );
    }

    function test_sqrt_one()
        public
        view
    {
        assertEq(
            math.sqrt(1),
            1
        );
    }

    function test_sqrt_two()
        public
        view
    {
        assertEq(
            math.sqrt(2),
            1
        );
    }

    function test_sqrt_three()
        public
        view
    {
        assertEq(
            math.sqrt(3),
            1
        );
    }

    function test_sqrt_four()
        public
        view
    {
        assertEq(
            math.sqrt(4),
            2
        );
    }

    function test_sqrt_perfectSquares()
        public
        view
    {
        assertEq(
            math.sqrt(9),
            3
        );

        assertEq(
            math.sqrt(16),
            4
        );

        assertEq(
            math.sqrt(25),
            5
        );

        assertEq(
            math.sqrt(100),
            10
        );

        assertEq(
            math.sqrt(1 ether),
            1_000_000_000
        );
    }

    function test_sqrt_roundsDown()
        public
        view
    {
        assertEq(
            math.sqrt(5),
            2
        );

        assertEq(
            math.sqrt(8),
            2
        );

        assertEq(
            math.sqrt(15),
            3
        );

        assertEq(
            math.sqrt(24),
            4
        );
    }

    function test_sqrt_maxUint()
        public
        view
    {
        uint256 result =
            math.sqrt(
                type(uint256).max
            );

        assertEq(
            result,
            type(uint128).max
        );
    }

    // ============================================================
    // SQRT - FUZZ
    // ============================================================

    function testFuzz_sqrt_lowerBound(
        uint256 x
    )
        public
        view
    {
        uint256 z =
            math.sqrt(x);

        if (z == 0) {
            assertEq(
                x,
                0
            );

            return;
        }

        assertLe(
            z,
            x
        );

        assertLe(
            z,
            type(uint128).max
        );
    }

    function testFuzz_sqrt_definition(
        uint128 raw
    )
        public
        view
    {
        uint256 x =
            uint256(raw);

        uint256 square =
            x * x;

        uint256 z =
            math.sqrt(square);

        assertEq(
            z,
            x
        );
    }

    function testFuzz_sqrt_roundingProperty(
        uint128 raw
    )
        public
        view
    {
        uint256 y =
            uint256(raw);

        uint256 z =
            math.sqrt(y);

        assertLe(
            z * z,
            y
        );

        if (
            z <
            type(uint128).max
        ) {
            uint256 next =
                z + 1;

            assertGt(
                next * next,
                y
            );
        }
    }

    function testFuzz_sqrt_monotonic(
        uint128 a,
        uint128 b
    )
        public
        view
    {
        uint256 x =
            uint256(a);

        uint256 y =
            uint256(b);

        if (x > y) {
            (
                x,
                y
            ) =
                (
                    y,
                    x
                );
        }

        assertLe(
            math.sqrt(x),
            math.sqrt(y)
        );
    }

    // ============================================================
    // UQ112x112 ENCODE
    // ============================================================

    function test_encode_zero()
        public
        view
    {
        assertEq(
            uq.encode(0),
            0
        );
    }

    function test_encode_one()
        public
        view
    {
        assertEq(
            uq.encode(1),
            Q112
        );
    }

    function test_encode_two()
        public
        view
    {
        assertEq(
            uq.encode(2),
            Q112 * 2
        );
    }

    function test_encode_maxUint112()
        public
        view
    {
        uint112 value =
            type(uint112).max;

        uint224 encoded =
            uq.encode(value);

        assertEq(
            encoded,
            uint224(value) *
                Q112
        );
    }

    function testFuzz_encode(
        uint112 value
    )
        public
        view
    {
        uint224 encoded =
            uq.encode(value);

        assertEq(
            encoded,
            uint224(value) *
                Q112
        );
    }

    function testFuzz_encode_monotonic(
        uint112 a,
        uint112 b
    )
        public
        view
    {
        if (a > b) {
            (
                a,
                b
            ) =
                (
                    b,
                    a
                );
        }

        assertLe(
            uq.encode(a),
            uq.encode(b)
        );
    }

    // ============================================================
    // UQDIV
    // ============================================================

    function test_uqdiv_basic()
        public
        view
    {
        uint224 encoded =
            uq.encode(10);

        uint224 result =
            uq.uqdiv(
                encoded,
                2
            );

        assertEq(
            result,
            Q112 * 5
        );
    }

    function test_uqdiv_one()
        public
        view
    {
        uint224 encoded =
            uq.encode(123);

        assertEq(
            uq.uqdiv(
                encoded,
                1
            ),
            encoded
        );
    }

    function test_uqdiv_zeroNumerator()
        public
        view
    {
        assertEq(
            uq.uqdiv(
                0,
                1
            ),
            0
        );
    }

    function test_uqdiv_revertsDivisionByZero()
        public
    {
        vm.expectRevert(
            UQ112x112.DivisionByZero.selector
        );

        uq.uqdiv(
            1,
            0
        );
    }

    function test_uqdiv_maxValues()
        public
        view
    {
        uint224 x =
            type(uint224).max;

        uint112 y =
            type(uint112).max;

        assertEq(
            uq.uqdiv(
                x,
                y
            ),
            x /
                uint224(y)
        );
    }

    function testFuzz_uqdiv_matchesNativeDivision(
        uint224 x,
        uint112 y
    )
        public
        view
    {
        vm.assume(
            y != 0
        );

        uint224 result =
            uq.uqdiv(
                x,
                y
            );

        assertEq(
            result,
            x /
                uint224(y)
        );
    }

    function testFuzz_uqdiv_resultNeverExceedsNumeratorForDivisorAboveOne(
        uint224 x,
        uint112 y
    )
        public
        view
    {
        vm.assume(
            y > 1
        );

        uint224 result =
            uq.uqdiv(
                x,
                y
            );

        assertLe(
            result,
            x
        );
    }

    // ============================================================
    // ENCODE + DIV INTEGRATION
    // ============================================================

    function test_encodeAndDivide_oneToOne()
        public
        view
    {
        uint224 encoded =
            uq.encode(100);

        uint224 result =
            uq.uqdiv(
                encoded,
                100
            );

        assertEq(
            result,
            Q112
        );
    }

    function test_encodeAndDivide_twoToOne()
        public
        view
    {
        uint224 encoded =
            uq.encode(200);

        uint224 result =
            uq.uqdiv(
                encoded,
                100
            );

        assertEq(
            result,
            Q112 * 2
        );
    }

    function testFuzz_encodeAndDivide(
        uint112 numerator,
        uint112 denominator
    )
        public
        view
    {
        vm.assume(
            denominator != 0
        );

        uint224 encoded =
            uq.encode(
                numerator
            );

        uint224 result =
            uq.uqdiv(
                encoded,
                denominator
            );

        uint224 expected =
            encoded /
                uint224(denominator);

        assertEq(
            result,
            expected
        );
    }
}