// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2RouterSwapMoreEdgeCasesTest is Test {
    ApexV2Factory factory;
    ApexV2Router router;
    MockERC20 weth;
    MockERC20 tokenA;
    MockERC20 tokenB;

    address user = address(0xA11cE);

    function setUp() public {
        factory = new ApexV2Factory(address(this));
        
        weth = new MockERC20("Wrapped Ether", "WETH");
        router = new ApexV2Router(address(factory), address(weth)); 

        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");

        tokenA.mint(user, 1000e18);
        tokenB.mint(user, 1000e18);

        vm.startPrank(user);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        vm.stopPrank();

        factory.createPair(address(tokenA), address(tokenB));
    }

    function test_RevertWhen_Swap_DuplicateTokens() public {
        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenA);

        vm.startPrank(user);
        vm.expectRevert(); 
        router.swapExactTokensForTokens(
            100e18, 
            1, 
            path, 
            user, 
            block.timestamp + 100
        );
        vm.stopPrank();
    }

    function test_RevertWhen_Swap_InsufficientOutputAmount() public {
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.startPrank(user);
        vm.expectRevert(); 
        router.swapExactTokensForTokens(
            10e18, 
            type(uint256).max, 
            path, 
            user, 
            block.timestamp + 100
        );
        vm.stopPrank();
    }
}