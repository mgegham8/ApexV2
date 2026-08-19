// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2PairSwapSecurityTest is Test {
    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    MockFactory factory;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        factory = new MockFactory();

        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));

        token0.mint(address(this), 10000 ether);

        token1.mint(address(this), 10000 ether);

        token0.transfer(address(pair), 1000 ether);

        token1.transfer(address(pair), 1000 ether);

        pair.mint(address(this));
    }

    function testSwapCannotBreakInvariant() public {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        uint256 kBefore = uint256(reserve0) * uint256(reserve1);

        token0.mint(address(this), 100 ether);

        token0.transfer(address(pair), 100 ether);

        pair.swap(0, 90 ether, address(this), "");

        (reserve0, reserve1,) = pair.getReserves();

        uint256 kAfter = uint256(reserve0) * uint256(reserve1);

        assertGe(kAfter, kBefore);
    }

    function testSwapZeroInputFails() public {
        vm.expectRevert();

        pair.swap(10 ether, 0, address(this), "");
    }

    function testSwapCannotSendToTokenAddress() public {
        token0.mint(address(pair), 100 ether);

        vm.expectRevert();

        pair.swap(0, 50 ether, address(token0), "");
    }

    function testSwapFeeAccounting() public {
        (uint112 reserve0Before, uint112 reserve1Before,) = pair.getReserves();

        uint256 kBefore = uint256(reserve0Before) * uint256(reserve1Before);

        token0.mint(address(this), 100 ether);

        token0.transfer(address(pair), 100 ether);

        pair.swap(0, 90 ether, address(this), "");

        (uint112 reserve0After, uint112 reserve1After,) = pair.getReserves();

        uint256 kAfter = uint256(reserve0After) * uint256(reserve1After);

        assertGe(kAfter, kBefore);
    }
}
