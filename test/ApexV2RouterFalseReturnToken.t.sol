// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";

import "../src/contracts/test/FalseReturnERC20.sol";
import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterFalseReturnTokenTest is Test {
    ApexV2Router router;
    ApexV2Factory factory;

    FalseReturnERC20 token0;
    FalseReturnERC20 token1;

    WETH9 weth;

    function setUp() public {
        weth = new WETH9();

        factory = new ApexV2Factory(address(this));

        router = new ApexV2Router(address(factory), address(weth));

        token0 = new FalseReturnERC20();

        token1 = new FalseReturnERC20();

        token0.mint(address(this), 1000 ether);

        token1.mint(address(this), 1000 ether);

        token0.approve(address(router), type(uint256).max);

        token1.approve(address(router), type(uint256).max);
    }

    function testRouterRejectsFalseReturnToken() public {
        vm.expectRevert();

        router.addLiquidity(
            address(token0), address(token1), 100 ether, 100 ether, 0, 0, address(this), block.timestamp + 1 hours
        );
    }
}
