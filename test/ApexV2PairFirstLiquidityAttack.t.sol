// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/test/MockERC20.sol";


contract ApexV2PairFirstLiquidityAttackTest is Test {


    ApexV2Factory factory;
    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;


    address attacker = address(100);
    address user = address(200);



    function setUp() public {


        token0 = new MockERC20(
            "Token0",
            "TK0"
        );


        token1 = new MockERC20(
            "Token1",
            "TK1"
        );


        factory =
            new ApexV2Factory(
                address(this)
            );


        address pairAddress =
            factory.createPair(
                address(token0),
                address(token1)
            );


        pair =
            ApexV2Pair(
                pairAddress
            );

    }




    /*
        Attack:
        First LP deposits tiny amount,
        then tries to abuse rounding
    */
    function testFirstLiquidityCannotCreateFreeLP()
        public
    {


        token0.mint(
            attacker,
            1000 ether
        );


        token1.mint(
            attacker,
            1000 ether
        );



        vm.startPrank(attacker);


        token0.transfer(
            address(pair),
            1000 ether
        );


        token1.transfer(
            address(pair),
            1000 ether
        );



        pair.mint(
            attacker
        );


        vm.stopPrank();



        uint lp =
            pair.balanceOf(
                attacker
            );



        // attacker cannot receive full supply
        assertLt(
            lp,
            1000 ether
        );


    }








    /*
        Attack:
        Donate after first liquidity
        Try to inflate reserves
    */
    function testDonationAfterFirstLiquidityCannotDrain()
        public
    {


        token0.mint(
            address(this),
            10000 ether
        );


        token1.mint(
            address(this),
            10000 ether
        );



        token0.transfer(
            address(pair),
            1000 ether
        );


        token1.transfer(
            address(pair),
            1000 ether
        );


        pair.mint(
            address(this)
        );



        token0.mint(
            attacker,
            1000 ether
        );


        vm.prank(attacker);


        token0.transfer(
            address(pair),
            1000 ether
        );



        (
            uint112 r0,
            uint112 r1,

        ) =
            pair.getReserves();



        assertEq(
            r0,
            1000 ether
        );


        assertEq(
            r1,
            1000 ether
        );

    }








    /*
        Attack:
        First LP tries tiny liquidity
    */
    function testTinyInitialLiquidityFails()
        public
    {


        token0.mint(
            attacker,
            1
        );


        token1.mint(
            attacker,
            1
        );



        vm.startPrank(attacker);



        token0.transfer(
            address(pair),
            1
        );


        token1.transfer(
            address(pair),
            1
        );



        vm.expectRevert();


        pair.mint(
            attacker
        );



        vm.stopPrank();

    }








    /*
        Verify minimum liquidity lock
    */
    function testMinimumLiquidityLocked()
        public
    {


        token0.mint(
            address(this),
            1000 ether
        );


        token1.mint(
            address(this),
            1000 ether
        );



        token0.transfer(
            address(pair),
            1000 ether
        );


        token1.transfer(
            address(pair),
            1000 ether
        );


        pair.mint(
            address(this)
        );



        assertEq(
            pair.balanceOf(
                address(0)
            ),
            1000
        );

    }


}