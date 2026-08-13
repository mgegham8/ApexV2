// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;


import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";

import "./handlers/ApexV2PairHandler.sol";



contract ApexV2PairInvariantTest is Test {


    ApexV2Pair public pair;

    MockERC20 public token0;
    MockERC20 public token1;


    ApexV2PairHandler public handler;



    uint256 public lastK;


    bool public poolInitialized;



    uint112 public lastReserve0;
    uint112 public lastReserve1;







    function setUp()
        public
    {


        token0 =
            new MockERC20(
                "Token0",
                "TK0"
            );


        token1 =
            new MockERC20(
                "Token1",
                "TK1"
            );



        pair =
            new ApexV2Pair();



        pair.initialize(
            address(token0),
            address(token1)
        );



        handler =
            new ApexV2PairHandler(
                pair,
                token0,
                token1
            );



        targetContract(
            address(handler)
        );

    }










    /*
        reserves <= balances
    */
    function invariant_reserves_not_bigger_than_balances()
        public
    {

        (
            uint112 reserve0,
            uint112 reserve1,

        ) = pair.getReserves();



        assertLe(
            reserve0,
            token0.balanceOf(
                address(pair)
            )
        );


        assertLe(
            reserve1,
            token1.balanceOf(
                address(pair)
            )
        );

    }









    /*
        uint112 overflow protection
    */
    function invariant_reserves_uint112()
        public
        view
    {

        (
            uint112 reserve0,
            uint112 reserve1,

        ) = pair.getReserves();



        assertLe(
            reserve0,
            type(uint112).max
        );


        assertLe(
            reserve1,
            type(uint112).max
        );

    }









    /*
        K should never decrease
    */
    function invariant_K_never_decreases()
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




        uint256 currentK =
            uint256(reserve0)
            *
            uint256(reserve1);




        if(lastK != 0)
        {

            assertGe(
                currentK,
                lastK,
                "K decreased"
            );

        }



        lastK = currentK;

    }









    /*
        sync correctness
    */
    function invariant_sync_state()
        public
    {


        uint balance0 =
            token0.balanceOf(
                address(pair)
            );


        uint balance1 =
            token1.balanceOf(
                address(pair)
            );



        if(
            balance0 > type(uint112).max ||
            balance1 > type(uint112).max
        )
        {
            return;
        }



        pair.sync();




        (
            uint112 reserve0,
            uint112 reserve1,

        ) = pair.getReserves();



        assertEq(
            reserve0,
            balance0
        );


        assertEq(
            reserve1,
            balance1
        );

    }









    /*
        reserves tracking
    */
    function invariant_reserve_tracking()
        public
    {


        (
            uint112 reserve0,
            uint112 reserve1,

        ) = pair.getReserves();



        if(poolInitialized)
        {

            assertGe(
                reserve0,
                0
            );


            assertGe(
                reserve1,
                0
            );

        }



        lastReserve0 =
            reserve0;


        lastReserve1 =
            reserve1;



        if(
            reserve0 > 0 &&
            reserve1 > 0
        )
        {
            poolInitialized = true;
        }

    }









    /*
        donation should not update reserves
    */
    function invariant_donation_not_update_reserves()
        public
    {


        (
            uint112 reserve0,
            uint112 reserve1,

        ) = pair.getReserves();



        uint balance0 =
            token0.balanceOf(
                address(pair)
            );


        uint balance1 =
            token1.balanceOf(
                address(pair)
            );



        if(
            balance0 > reserve0 ||
            balance1 > reserve1
        )
        {

            assertGe(
                balance0,
                reserve0
            );


            assertGe(
                balance1,
                reserve1
            );

        }

    }









    /*
        LP supply safety
    */
    function invariant_total_supply_valid()
        public
        view
    {


        uint256 supply =
            pair.totalSupply();



        assertLe(
            supply,
            type(uint256).max
        );



        if(poolInitialized)
        {

            assertGe(
                supply,
                pair.MINIMUM_LIQUIDITY()
            );

        }

    }









    /*
        skim should not break reserves
    */
    function invariant_skim_safe()
        public
    {

        pair.skim(
            address(handler)
        );


        (
            uint112 reserve0,
            uint112 reserve1,

        ) = pair.getReserves();



        assertLe(
            reserve0,
            token0.balanceOf(
                address(pair)
            )
        );


        assertLe(
            reserve1,
            token1.balanceOf(
                address(pair)
            )
        );

    }

}