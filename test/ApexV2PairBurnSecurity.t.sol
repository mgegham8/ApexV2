// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";


contract ApexV2PairBurnSecurityTest is Test {


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

    }





    function testBurnReturnsCorrectAmounts()
    public
    {

        uint liquidity =
            pair.balanceOf(
                address(this)
            );


        pair.transfer(
            address(pair),
            liquidity / 2
        );



        uint token0Before =
            token0.balanceOf(
                address(this)
            );


        uint token1Before =
            token1.balanceOf(
                address(this)
            );



        pair.burn(
            address(this)
        );



        uint token0After =
            token0.balanceOf(
                address(this)
            );


        uint token1After =
            token1.balanceOf(
                address(this)
            );



        assertGt(
            token0After,
            token0Before
        );


        assertGt(
            token1After,
            token1Before
        );

    }







    function testBurnCannotStealMoreThanLiquidity()
    public
    {

        uint liquidity =
            pair.balanceOf(
                address(this)
            );


        pair.transfer(
            address(pair),
            liquidity
        );



        uint balance0Before =
            token0.balanceOf(
                address(pair)
            );


        uint balance1Before =
            token1.balanceOf(
                address(pair)
            );



        pair.burn(
            address(this)
        );



        uint balance0After =
            token0.balanceOf(
                address(pair)
            );


        uint balance1After =
            token1.balanceOf(
                address(pair)
            );



        assertLt(
            balance0After,
            balance0Before
        );


        assertLt(
            balance1After,
            balance1Before
        );

    }







    function testBurnWithFeeOnMintsProtocolFee()
    public
    {

        address feeReceiver =
            address(0x123);



        factory.setFeeTo(
            feeReceiver
        );



        // increase liquidity and create kLast

        token0.mint(
            address(pair),
            100 ether
        );


        token1.mint(
            address(pair),
            100 ether
        );


        pair.mint(
            address(this)
        );



        // generate fee growth

        token0.mint(
            address(this),
            100 ether
        );


        token0.transfer(
            address(pair),
            100 ether
        );


        pair.swap(
            0,
            90 ether,
            address(this),
            ""
        );



        // burn triggers _mintFee()

        uint liquidity =
            pair.balanceOf(
                address(this)
            );


        pair.transfer(
            address(pair),
            liquidity / 2
        );



        pair.burn(
            address(this)
        );



        uint feeLiquidity =
            pair.balanceOf(
                feeReceiver
            );



        assertGt(
            feeLiquidity,
            0
        );

    }







    function testBurnZeroLiquidityFails()
    public
    {

        vm.expectRevert();


        pair.burn(
            address(this)
        );

    }

}