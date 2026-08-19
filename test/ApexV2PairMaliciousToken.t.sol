// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFeeToken.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2PairMaliciousTokenTest is Test {
    ApexV2Pair pair;

    MockFeeToken feeToken;
    MockERC20 token1;

    MockFactory factory;

    function setUp() public {
        feeToken = new MockFeeToken();

        token1 = new MockERC20("Token1", "TK1");

        factory = new MockFactory();

        pair = ApexV2Pair(factory.createPair(address(feeToken), address(token1)));

        feeToken.mint(address(this), 10000 ether);

        token1.mint(address(this), 10000 ether);

        feeToken.transfer(address(pair), 1000 ether);

        token1.transfer(address(pair), 1000 ether);

        pair.mint(address(this));
    }

    function feeTokenReserve() internal view returns (uint112 reserve) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        if (pair.token0() == address(feeToken)) {
            reserve = reserve0;
        } else {
            reserve = reserve1;
        }
    }

    function token1Reserve() internal view returns (uint112 reserve) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        if (pair.token0() == address(token1)) {
            reserve = reserve0;
        } else {
            reserve = reserve1;
        }
    }

    function testFeeTokenCannotCreateFakeReserve() public {
        uint256 balanceBefore = feeToken.balanceOf(address(pair));

        feeToken.mint(address(this), 100 ether);

        feeToken.transfer(address(pair), 100 ether);

        uint256 balanceAfter = feeToken.balanceOf(address(pair));

        assertLt(balanceAfter - balanceBefore, 100 ether);

        pair.sync();

        assertEq(feeTokenReserve(), balanceAfter);

        assertEq(token1Reserve(), token1.balanceOf(address(pair)));
    }

    function testFeeTokenSwapKeepsInvariant() public {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        uint256 kBefore = uint256(reserve0) * uint256(reserve1);

        feeToken.mint(address(this), 100 ether);

        feeToken.transfer(address(pair), 100 ether);

        pair.swap(0, 50 ether, address(this), "");

        (uint112 reserve0After, uint112 reserve1After,) = pair.getReserves();

        uint256 kAfter = uint256(reserve0After) * uint256(reserve1After);

        assertGe(kAfter, kBefore);
    }

    function testDonationDoesNotChangeReserve() public {
        uint112 before = feeTokenReserve();

        feeToken.mint(address(this), 100 ether);

        feeToken.transfer(address(pair), 100 ether);

        uint112 afterReserve = feeTokenReserve();

        assertEq(before, afterReserve);
    }

    function testSyncWithFeeTokenUsesRealBalance() public {
        feeToken.mint(address(this), 100 ether);

        feeToken.transfer(address(pair), 100 ether);

        uint256 realBalance = feeToken.balanceOf(address(pair));

        pair.sync();

        assertEq(feeTokenReserve(), realBalance);
    }
}
