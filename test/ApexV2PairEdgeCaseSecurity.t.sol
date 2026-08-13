// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";


contract ApexV2PairEdgeCaseSecurityTest is Test {


    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    MockFactory factory;



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



        factory = new MockFactory();



        pair =
            ApexV2Pair(
                factory.createPair(
                    address(token0),
                    address(token1)
                )
            );



        token0.mint(
            address(this),
            100000 ether
        );


        token1.mint(
            address(this),
            100000 ether
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

    }








    function testSkimCannotStealReserves()
    public
    {

        (
            uint112 r0,
            uint112 r1,

        ) =
            pair.getReserves();



        pair.skim(
            address(this)
        );



        (
            uint112 r0After,
            uint112 r1After,

        ) =
            pair.getReserves();



        assertEq(
            r0After,
            r0
        );


        assertEq(
            r1After,
            r1
        );

    }










    function testSyncUpdatesDonationOnly()
    public
    {

        token0.mint(
            address(pair),
            100 ether
        );


        token1.mint(
            address(pair),
            100 ether
        );



        pair.sync();



        (
            uint112 r0,
            uint112 r1,

        ) =
            pair.getReserves();



        assertEq(
            r0,
            1100 ether
        );


        assertEq(
            r1,
            1100 ether
        );

    }









    function testTinyLiquidityCannotMintFreeTokens()
    public
    {

        MockERC20 tinyToken0 =
            new MockERC20(
                "Tiny0",
                "T0"
            );


        MockERC20 tinyToken1 =
            new MockERC20(
                "Tiny1",
                "T1"
            );



        ApexV2Pair tinyPair =
            ApexV2Pair(
                factory.createPair(
                    address(tinyToken0),
                    address(tinyToken1)
                )
            );



        tinyToken0.mint(
            address(this),
            10
        );


        tinyToken1.mint(
            address(this),
            10
        );



        tinyToken0.transfer(
            address(tinyPair),
            1
        );


        tinyToken1.transfer(
            address(tinyPair),
            1
        );



        vm.expectRevert();



        tinyPair.mint(
            address(this)
        );

    }










    function testRoundingCannotCreateLiquidity()
    public
    {

        uint supplyBefore =
            pair.totalSupply();



        token0.mint(
            address(pair),
            1
        );


        token1.mint(
            address(pair),
            1
        );



        pair.mint(
            address(this)
        );



        uint supplyAfter =
            pair.totalSupply();



        assertGt(
            supplyAfter,
            supplyBefore
        );

    }










    function testReserveCannotExceedUint112()
    public
    {

        uint huge =
            uint(type(uint112).max);



        token0.mint(
            address(pair),
            huge
        );


        token1.mint(
            address(pair),
            huge
        );



        vm.expectRevert();


        pair.sync();

    }










    function testExtremeSwapFailsSafely()
    public
    {

        vm.expectRevert();


        pair.swap(
            type(uint112).max,
            0,
            address(this),
            ""
        );

    }

}