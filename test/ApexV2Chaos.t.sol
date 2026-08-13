// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2ChaosTest is Test {
    ApexV2Factory factory;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;
    address attacker = address(0x1337);
    uint256 initialReserve0;
    uint256 initialReserve1;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        factory = new ApexV2Factory(address(this));
        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));

        token0.mint(address(this), 1_000_000 ether);
        token1.mint(address(this), 1_000_000 ether);
        token0.transfer(address(pair), 100_000 ether);
        token1.transfer(address(pair), 100_000 ether);
        pair.mint(address(this));

        (initialReserve0, initialReserve1, ) = pair.getReserves();
        vm.deal(attacker, 100 ether);
    }

    function testChaosAttack() public {
        vm.startPrank(attacker);

        token0.mint(attacker, 10_000 ether);
        token1.mint(attacker, 10_000 ether);

        // Attacker keeps 5,000 ether in wallet and sends 5,000 ether to the pair
        token0.transfer(address(pair), 5_000 ether);
        token1.transfer(address(pair), 5_000 ether);

        try pair.swap(1000 ether, 0, attacker, "") {} catch {}
        try pair.sync() {} catch {}
        try pair.skim(attacker) {} catch {}
        try pair.swap(0, 500 ether, attacker, "") {} catch {}

        vm.stopPrank();

        // Attacker should not be able to steal back the donated tokens or extract extra profit
        // Max expected balance is the 5,000 left in wallet plus a small margin
        assertLe(token0.balanceOf(attacker), 5_100 ether);
    }

    function testReserveInvariant() public {
        (uint112 r0, uint112 r1, ) = pair.getReserves();
        assertGt(r0, 0);
        assertGt(r1, 0);
        assertLe(r0, initialReserve0 + 10_000 ether);
        assertLe(r1, initialReserve1 + 10_000 ether);
    }

    function testRandomChaosSequence() public {
        for (uint256 i = 0; i < 50; i++) {
            uint256 action = uint256(keccak256(abi.encode(i))) % 4;
            if (action == 0) {
                try pair.sync() {} catch {}
            } else if (action == 1) {
                try pair.skim(attacker) {} catch {}
            } else if (action == 2) {
                try pair.swap(1 ether, 0, attacker, "") {} catch {}
            } else {
                try pair.swap(0, 1 ether, attacker, "") {} catch {}
            }
        }
        (uint112 r0, uint112 r1, ) = pair.getReserves();
        assertGt(r0, 0);
        assertGt(r1, 0);
    }
}