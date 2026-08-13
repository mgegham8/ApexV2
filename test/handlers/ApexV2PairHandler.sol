// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;


import "forge-std/Test.sol";


import "../../src/contracts/ApexV2Pair.sol";
import "../../src/contracts/test/MockERC20.sol";



contract ApexV2PairHandler is Test {


    ApexV2Pair public pair;


    MockERC20 public token0;
    MockERC20 public token1;



    uint256 public addLiquidityCalls;
    uint256 public removeLiquidityCalls;
    uint256 public swapCalls;
    uint256 public donationCalls;
    uint256 public syncCalls;
    uint256 public skimCalls;





    constructor(
        ApexV2Pair _pair,
        MockERC20 _token0,
        MockERC20 _token1
    )
    {

        pair = _pair;

        token0 = _token0;

        token1 = _token1;



        token0.approve(
            address(pair),
            type(uint256).max
        );


        token1.approve(
            address(pair),
            type(uint256).max
        );

    }









    /*
        Add liquidity
    */
    function addLiquidity(
        uint256 amount0,
        uint256 amount1
    )
        public
    {


        amount0 = bound(
            amount0,
            1e6,
            1e24
        );


        amount1 = bound(
            amount1,
            1e6,
            1e24
        );





        token0.mint(
            address(this),
            amount0
        );


        token1.mint(
            address(this),
            amount1
        );





        token0.transfer(
            address(pair),
            amount0
        );


        token1.transfer(
            address(pair),
            amount1
        );





        pair.mint(
            address(this)
        );



        addLiquidityCalls++;

    }









    /*
        Remove liquidity
    */
    function removeLiquidity(
        uint256 liquidity
    )
        public
    {


        uint256 balance =
            pair.balanceOf(
                address(this)
            );



        if(balance == 0)
        {
            return;
        }





        liquidity =
            bound(
                liquidity,
                1,
                balance
            );





        pair.transfer(
            address(pair),
            liquidity
        );



        pair.burn(
            address(this)
        );



        removeLiquidityCalls++;

    }









    /*
        Normal swap token0 -> token1
    */
    function swap(
        uint256 amount0In
    )
        public
    {


        (
            uint112 reserve0,
            uint112 reserve1,

        ) = pair.getReserves();




        if(
            reserve0 == 0 ||
            reserve1 == 0
        )
        {
            return;
        }





        amount0In =
            bound(
                amount0In,
                1e6,
                reserve0 / 5
            );







        token0.mint(
            address(this),
            amount0In
        );




        token0.transfer(
            address(pair),
            amount0In
        );







        uint256 amount1Out =
            (
                amount0In *
                997 *
                reserve1
            )
            /
            (
                reserve0 *
                1000
                +
                amount0In *
                997
            );





        if(amount1Out == 0)
        {
            return;
        }






        pair.swap(
            0,
            amount1Out,
            address(this),
            ""
        );



        swapCalls++;

    }









    /*
        Direct token transfer
        without mint()
    */
    function donation(
        uint256 amount0,
        uint256 amount1
    )
        public
    {



        amount0 =
            bound(
                amount0,
                1,
                1e24
            );



        amount1 =
            bound(
                amount1,
                1,
                1e24
            );







        token0.mint(
            address(this),
            amount0
        );



        token1.mint(
            address(this),
            amount1
        );







        token0.transfer(
            address(pair),
            amount0
        );


        token1.transfer(
            address(pair),
            amount1
        );




        donationCalls++;

    }









    /*
        Update reserves
    */
    function sync()
        public
    {

        pair.sync();


        syncCalls++;

    }









    /*
        Remove excess tokens
    */
    function skim()
        public
    {

        pair.skim(
            address(this)
        );


        skimCalls++;

    }

}