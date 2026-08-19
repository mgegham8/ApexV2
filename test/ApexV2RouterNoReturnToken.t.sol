// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";

import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/NoReturnERC20.sol";
import "../src/contracts/test/WETH9.sol";

contract ApexV2RouterNoReturnTokenTest is Test {
    ApexV2Factory public factory;
    ApexV2Router public router;
    WETH9 public weth;

    NoReturnERC20 public token0;
    MockERC20 public token1;

    address public user = address(1);

    function setUp() public {
        weth = new WETH9();

        factory = new ApexV2Factory(address(this));

        router = new ApexV2Router(address(factory), address(weth));

        token0 = new NoReturnERC20();

        token1 = new MockERC20("Token1", "TK1");

        token0.mint(user, 1000 ether);

        token1.mint(user, 1000 ether);

        vm.startPrank(user);

        token0.approve(address(router), type(uint256).max);

        token1.approve(address(router), type(uint256).max);

        vm.stopPrank();
    }

    function testRouterAcceptsNoReturnToken() public {
        vm.startPrank(user);

        (uint256 amount0, uint256 amount1, uint256 liquidity) = router.addLiquidity(
            address(token0), address(token1), 100 ether, 100 ether, 90 ether, 90 ether, user, block.timestamp + 1 days
        );

        vm.stopPrank();

        assertEq(amount0, 100 ether);

        assertEq(amount1, 100 ether);

        assertGt(liquidity, 0);

        address pair = factory.getPair(address(token0), address(token1));

        assertTrue(pair != address(0));

        assertEq(token0.balanceOf(pair), 100 ether);

        assertEq(token1.balanceOf(pair), 100 ether);
    }
}
