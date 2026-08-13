// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2RouterPathAttackTest is Test {
    ApexV2Factory factory;
    ApexV2Router router;
    MockERC20 token0;
    MockERC20 token1;
    MockERC20 token2;
    MockERC20 weth;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        token2 = new MockERC20("Token2", "TK2");
        weth = new MockERC20("WETH", "WETH");

        factory = new ApexV2Factory(address(this));
        router = new ApexV2Router(address(factory), address(weth));
    }

    function testPathLengthZeroOrOne() public {
        address[] memory emptyPath = new address[](0);
        address[] memory singlePath = new address[](1);
        singlePath[0] = address(token0);

        token0.mint(address(this), 100 ether);
        token0.approve(address(router), 100 ether);

        vm.expectRevert();
        router.swapExactTokensForTokens(10 ether, 0, emptyPath, address(this), block.timestamp);

        vm.expectRevert();
        router.swapExactTokensForTokens(10 ether, 0, singlePath, address(this), block.timestamp);
    }

    function testDuplicateTokensInPath() public {
        address[] memory path = new address[](3);
        path[0] = address(token0);
        path[1] = address(token0);
        path[2] = address(token1);

        token0.mint(address(this), 100 ether);
        token0.approve(address(router), 100 ether);

        vm.expectRevert();
        router.swapExactTokensForTokens(10 ether, 0, path, address(this), block.timestamp);
    }

    function testFakePairPath() public {
        // Path with tokens that have no created pair
        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token2);

        token0.mint(address(this), 100 ether);
        token0.approve(address(router), 100 ether);

        vm.expectRevert();
        router.swapExactTokensForTokens(10 ether, 0, path, address(this), block.timestamp);
    }
}