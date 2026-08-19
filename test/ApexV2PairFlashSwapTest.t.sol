// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";
import "./attacks/FlashSwapAttacker.sol";
import "../src/contracts/interfaces/IApexV2Callee.sol";

contract ApexV2PairFlashSwapTest is Test {
    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    FlashSwapAttacker attacker;

    MockFactory factory;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        factory = new MockFactory();

        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));

        token0.mint(address(this), 1000 ether);

        token1.mint(address(this), 1000 ether);

        token0.transfer(address(pair), 500 ether);

        token1.transfer(address(pair), 500 ether);

        pair.mint(address(this));

        attacker = new FlashSwapAttacker(address(pair));

        token0.mint(address(attacker), 100 ether);

        token1.mint(address(attacker), 100 ether);
    }

    function testFlashSwapCallback() public {
        attacker.setRepay(true);

        attacker.attack(10 ether, 0);
    }

    function testFlashSwapNoRepay() public {
        attacker.setRepay(false);

        vm.expectRevert();

        attacker.attack(10 ether, 0);
    }

    function testFlashSwapToken1() public {
        attacker.setRepay(true);

        attacker.attack(0, 10 ether);
    }
}

contract ApexV2PairFlashSwapSecurityTest is Test, IApexV2Callee {
    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    MockFactory factory;

    bool repay;
    bool reenter;

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

        repay = false;
        reenter = false;
    }

    function testFlashSwapMustRepay() public {
        vm.expectRevert();

        pair.swap(100 ether, 0, address(this), abi.encode(1));
    }

    function testFlashSwapWrongRepaymentFails() public {
        vm.expectRevert();

        pair.swap(100 ether, 0, address(this), abi.encode(2));
    }

    function testFlashSwapCannotReenter() public {
        reenter = true;

        vm.expectRevert();

        pair.swap(100 ether, 0, address(this), abi.encode(3));
    }

    function apexV2Call(address, uint256 amount0, uint256 amount1, bytes calldata data) external {
        if (reenter) {
            pair.swap(1 ether, 0, address(this), "");
        }

        uint256 mode = abi.decode(data, (uint256));

        if (mode == 1) {
            return;
        }

        if (mode == 2) {
            token0.transfer(address(pair), 1 ether);

            return;
        }

        if (mode == 3) {
            return;
        }

        if (amount0 > 0) {
            token0.transfer(address(pair), (amount0 * 1003) / 997 + 1);
        }

        if (amount1 > 0) {
            token1.transfer(address(pair), (amount1 * 1003) / 997 + 1);
        }
    }
}
