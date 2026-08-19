// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/libraries/UQ112x112.sol";

contract UQ112x112Harness {
    function encode(uint112 y) external pure returns (uint224) {
        return UQ112x112.encode(y);
    }

    function uqdiv(uint224 x, uint112 y) external pure returns (uint224) {
        return UQ112x112.uqdiv(x, y);
    }
}

contract UQ112x112FinalSecurityTest is Test {
    UQ112x112Harness internal harness;

    uint224 internal constant Q112 = uint224(1) << 112;

    function setUp() public {
        harness = new UQ112x112Harness();
    }

    function test_encode_zero() public view {
        assertEq(harness.encode(0), 0);
    }

    function test_encode_one() public view {
        assertEq(harness.encode(1), Q112);
    }

    function test_encode_two() public view {
        assertEq(harness.encode(2), Q112 * 2);
    }

    function test_encode_maxUint112() public view {
        uint112 value = type(uint112).max;

        uint224 result = harness.encode(value);

        uint224 expected = uint224(value) * Q112;

        assertEq(result, expected);
    }

    function testFuzz_encode_matchesShift(uint112 value) public view {
        uint224 result = harness.encode(value);

        uint224 expected = uint224(value) << 112;

        assertEq(result, expected);
    }

    function testFuzz_encode_monotonic(uint112 a, uint112 b) public view {
        if (a > b) {
            (a, b) = (b, a);
        }

        assertLe(harness.encode(a), harness.encode(b));
    }

    function test_uqdiv_basic() public view {
        uint224 encoded = harness.encode(10);

        uint224 result = harness.uqdiv(encoded, 2);

        assertEq(result, Q112 * 5);
    }

    function test_uqdiv_divisorOne() public view {
        uint224 x = harness.encode(123);

        assertEq(harness.uqdiv(x, 1), x);
    }

    function test_uqdiv_zeroNumerator() public view {
        assertEq(harness.uqdiv(0, 1), 0);
    }

    function test_uqdiv_maxValues() public view {
        uint224 x = type(uint224).max;

        uint112 y = type(uint112).max;

        assertEq(harness.uqdiv(x, y), x / uint224(y));
    }

    function test_uqdiv_revertsDivisionByZero() public {
        vm.expectRevert(UQ112x112.DivisionByZero.selector);

        harness.uqdiv(1, 0);
    }

    function testFuzz_uqdiv_matchesNativeDivision(uint224 x, uint112 y) public view {
        vm.assume(y != 0);

        uint224 result = harness.uqdiv(x, y);

        uint224 expected = x / uint224(y);

        assertEq(result, expected);
    }

    function testFuzz_uqdiv_neverExceedsNumerator(uint224 x, uint112 y) public view {
        vm.assume(y >= 1);

        uint224 result = harness.uqdiv(x, y);

        assertLe(result, x);
    }

    function test_encodeThenDivide_oneToOne() public view {
        uint224 encoded = harness.encode(100);

        uint224 result = harness.uqdiv(encoded, 100);

        assertEq(result, Q112);
    }

    function test_encodeThenDivide_twoToOne() public view {
        uint224 encoded = harness.encode(200);

        uint224 result = harness.uqdiv(encoded, 100);

        assertEq(result, Q112 * 2);
    }

    function testFuzz_encodeThenDivide_matchesFormula(uint112 numerator, uint112 denominator) public view {
        vm.assume(denominator != 0);

        uint224 encoded = harness.encode(numerator);

        uint224 actual = harness.uqdiv(encoded, denominator);

        uint224 expected = encoded / uint224(denominator);

        assertEq(actual, expected);
    }

    function testFuzz_encodeThenDivide_integerRatio(uint112 base, uint112 multiplier) public view {
        vm.assume(base > 0);

        vm.assume(multiplier > 0);

        vm.assume(uint256(base) * uint256(multiplier) <= type(uint112).max);

        uint112 numerator = uint112(uint256(base) * uint256(multiplier));

        uint224 encoded = harness.encode(numerator);

        uint224 result = harness.uqdiv(encoded, base);

        assertEq(result, Q112 * uint224(multiplier));
    }
}
