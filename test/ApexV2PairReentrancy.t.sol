// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;


import {Test} from "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/test/MockERC20.sol";

import "./attacks/ReentrantSwapAttacker.sol";


contract ApexV2PairReentrancyTest is Test {


    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    ApexV2Factory factory;



    function setUp()
        public
    {

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
            ApexV2Pair(pairAddress);



        token0.mint(
            address(this),
            100 ether
        );


        token1.mint(
            address(this),
            100 ether
        );


        token0.transfer(
            address(pair),
            100 ether
        );


        token1.transfer(
            address(pair),
            100 ether
        );


        pair.mint(
            address(this)
        );

    }





    function testReentrancyBlocked()
        public
    {


        ReentrantSwapAttacker attacker =
            new ReentrantSwapAttacker(
                address(pair)
            );


        vm.expectRevert(
            ApexV2Pair.Locked.selector
        );


        attacker.attack();


    }


}