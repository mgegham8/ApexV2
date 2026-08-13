// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";

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


        // Deploy WETH
        weth = new WETH9();


        // Deploy Factory
        factory = new ApexV2Factory(
            address(this)
        );


        // Deploy Router
        router = new ApexV2Router(
            address(factory),
            address(weth)
        );



        // Deploy tokens
        token0 = new NoReturnERC20();

        token1 = new MockERC20(
            "Token1",
            "TK1"
        );



        // Create Pair
        factory.createPair(
            address(token0),
            address(token1)
        );



        // Mint tokens
        token0.mint(
            user,
            1000 ether
        );


        token1.mint(
            user,
            1000 ether
        );



        // Approve Router
        vm.startPrank(user);


        token0.approve(
            address(router),
            type(uint256).max
        );


        token1.approve(
            address(router),
            type(uint256).max
        );


        vm.stopPrank();
    }




    function testRouterRejectsNoReturnToken() public {


        vm.startPrank(user);



        // Router-ը պետք է reject անի
        // ERC20 որը չի վերադարձնում bool


        vm.expectRevert();



        router.addLiquidity(
            address(token0),
            address(token1),
            100 ether,
            100 ether,
            90 ether,
            90 ether,
            user,
            block.timestamp + 1 days
        );



        vm.stopPrank();
    }

}