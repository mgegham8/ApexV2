// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2RouterMultiHopSecurityTest is Test {
    ApexV2Router router;

    MockFactory factory;

    MockERC20 token0;
    MockERC20 token1;
    MockERC20 token2;

    ApexV2Pair pair01;
    ApexV2Pair pair12;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        token2 = new MockERC20("Token2", "TK2");

        factory = new MockFactory();

        router = new ApexV2Router(address(factory), address(0x123));

        token0.mint(address(this), 100000 ether);

        token1.mint(address(this), 100000 ether);

        token2.mint(address(this), 100000 ether);

        token0.approve(address(router), type(uint256).max);

        token1.approve(address(router), type(uint256).max);

        token2.approve(address(router), type(uint256).max);

        router.addLiquidity(
            address(token0), address(token1), 30000 ether, 30000 ether, 0, 0, address(this), block.timestamp + 1 hours
        );

        router.addLiquidity(
            address(token1), address(token2), 30000 ether, 30000 ether, 0, 0, address(this), block.timestamp + 1 hours
        );

        pair01 = ApexV2Pair(factory.getPair(address(token0), address(token1)));

        pair12 = ApexV2Pair(factory.getPair(address(token1), address(token2)));
    }

    function testMultiHopSwapWorks() public {
        address[] memory path = new address[](3);

        path[0] = address(token0);
        path[1] = address(token1);
        path[2] = address(token2);

        uint256 beforeBalance = token2.balanceOf(address(this));

        router.swapExactTokensForTokens(1000 ether, 1 ether, path, address(this), block.timestamp + 1 hours);

        uint256 afterBalance = token2.balanceOf(address(this));

        assertGt(afterBalance, beforeBalance);
    }

    function testMultiHopInvalidPathFails() public {
        address[] memory path = new address[](1);

        path[0] = address(token0);

        vm.expectRevert();

        router.swapExactTokensForTokens(100 ether, 0, path, address(this), block.timestamp + 1 hours);
    }

    function testMultiHopMissingPairFails() public {
        MockERC20 fake = new MockERC20("Fake", "FAKE");

        address[] memory path = new address[](3);

        path[0] = address(token0);
        path[1] = address(fake);
        path[2] = address(token2);

        vm.expectRevert();

        router.swapExactTokensForTokens(100 ether, 0, path, address(this), block.timestamp + 1 hours);
    }

    function testMultiHopCannotDrainPool() public {
        address[] memory path = new address[](3);

        path[0] = address(token0);
        path[1] = address(token1);
        path[2] = address(token2);

        vm.expectRevert();

        router.swapExactTokensForTokens(90000 ether, 1 ether, path, address(this), block.timestamp + 1 hours);
    }
}
