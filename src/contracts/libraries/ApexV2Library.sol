// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "../interfaces/IApexV2Factory.sol";
import "../interfaces/IApexV2Pair.sol";


library ApexV2Library {


    function sortTokens(
        address tokenA,
        address tokenB
    )
        internal
        pure
        returns(
            address token0,
            address token1
        )
    {

        require(
            tokenA != tokenB,
            "IDENTICAL_ADDRESSES"
        );


        require(
            tokenA != address(0),
            "ZERO_ADDRESS"
        );


        (token0, token1) =
            tokenA < tokenB
            ?
            (tokenA, tokenB)
            :
            (tokenB, tokenA);

    }




    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns(address pair)
    {

        pair =
            IApexV2Factory(factory)
            .getPair(
                tokenA,
                tokenB
            );


        require(
            pair != address(0),
            "PAIR_NOT_FOUND"
        );

    }





    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns(
            uint reserveA,
            uint reserveB
        )
    {


        address pair =
            pairFor(
                factory,
                tokenA,
                tokenB
            );



        (
            uint reserve0,
            uint reserve1,

        ) =
            IApexV2Pair(pair)
            .getReserves();



        (
            address token0,

        ) =
            sortTokens(
                tokenA,
                tokenB
            );



        if(tokenA == token0)
        {

            reserveA = reserve0;
            reserveB = reserve1;

        }
        else
        {

            reserveA = reserve1;
            reserveB = reserve0;

        }

    }





    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    )
        internal
        pure
        returns(uint amountB)
    {

        require(
            amountA > 0,
            "INSUFFICIENT_AMOUNT"
        );


        require(
            reserveA > 0 &&
            reserveB > 0,
            "INSUFFICIENT_LIQUIDITY"
        );


        amountB =
            amountA *
            reserveB /
            reserveA;

    }






    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    )
        internal
        pure
        returns(uint amountOut)
    {

        require(
            amountIn > 0,
            "INSUFFICIENT_INPUT"
        );


        require(
            reserveIn > 0 &&
            reserveOut > 0,
            "INSUFFICIENT_LIQUIDITY"
        );



        uint amountInWithFee =
            amountIn *
            997;



        uint numerator =
            amountInWithFee *
            reserveOut;



        uint denominator =
            reserveIn *
            1000
            +
            amountInWithFee;



        amountOut =
            numerator /
            denominator;

    }





    function getAmountsOut(
        address factory,
        uint amountIn,
        address[] memory path
    )
        internal
        view
        returns(uint[] memory amounts)
    {


        require(
            path.length >= 2,
            "INVALID_PATH"
        );


        amounts =
            new uint[](
                path.length
            );


        amounts[0] =
            amountIn;



        for(
            uint i = 0;
            i < path.length - 1;
            i++
        )
        {

            (
                uint reserveIn,
                uint reserveOut
            ) =
                getReserves(
                    factory,
                    path[i],
                    path[i+1]
                );


            amounts[i+1] =
                getAmountOut(
                    amounts[i],
                    reserveIn,
                    reserveOut
                );

        }

    }






    function getAmountsForLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired
    )
        internal
        view
        returns(
            uint amountA,
            uint amountB
        )
    {


        (
            uint reserveA,
            uint reserveB
        ) =
            getReserves(
                factory,
                tokenA,
                tokenB
            );



        if(
            reserveA == 0 &&
            reserveB == 0
        )
        {

            amountA = amountADesired;
            amountB = amountBDesired;

        }
        else
        {

            uint amountBOptimal =
                quote(
                    amountADesired,
                    reserveA,
                    reserveB
                );


            if(
                amountBOptimal <= amountBDesired
            )
            {

                amountA = amountADesired;
                amountB = amountBOptimal;

            }
            else
            {

                amountA =
                    quote(
                        amountBDesired,
                        reserveB,
                        reserveA
                    );


                amountB =
                    amountBDesired;

            }

        }

    }

}