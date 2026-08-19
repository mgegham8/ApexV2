// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2RouterRemoveLiquiditySecurityTest is Test {
    ApexV2Router router;

    MockFactory factory;

    MockERC20 token0;
    MockERC20 token1;

    ApexV2Pair pair;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        factory = new MockFactory();

        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));

        router = new ApexV2Router(address(factory), address(0x123));

        token0.mint(address(this), 10000 ether);

        token1.mint(address(this), 10000 ether);

        token0.approve(address(router), type(uint256).max);

        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(
            address(token0), address(token1), 5000 ether, 5000 ether, 0, 0, address(this), block.timestamp + 1 hours
        );
    }

    function testRemoveLiquidityWorks() public {
        uint256 lpBalance = pair.balanceOf(address(this));

        pair.approve(address(router), lpBalance);

        (uint256 amount0, uint256 amount1) = router.removeLiquidity(
            address(token0), address(token1), lpBalance, 1 ether, 1 ether, address(this), block.timestamp + 1 hours
        );

        assertGt(amount0, 0);

        assertGt(amount1, 0);
    }

    function testRemoveWithoutLPFails() public {
        vm.expectRevert();

        router.removeLiquidity(
            address(token0), address(token1), 100 ether, 0, 0, address(this), block.timestamp + 1 hours
        );
    }

    function testRemoveSlippageProtection() public {
        uint256 lpBalance = pair.balanceOf(address(this));

        pair.approve(address(router), lpBalance);

        vm.expectRevert();

        router.removeLiquidity(
            address(token0),
            address(token1),
            lpBalance,
            100000 ether,
            100000 ether,
            address(this),
            block.timestamp + 1 hours
        );
    }

    function testRemoveUpdatesReserves() public {
        uint256 lpBalance = pair.balanceOf(address(this));

        pair.approve(address(router), lpBalance);

        router.removeLiquidity(
            address(token0), address(token1), lpBalance, 0, 0, address(this), block.timestamp + 1 hours
        );

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        assertLt(reserve0, 5000 ether);

        assertLt(reserve1, 5000 ether);
    }
}
