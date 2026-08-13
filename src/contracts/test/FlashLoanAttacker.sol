// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IApexPair {

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    )
    external;


    function token0()
    external
    view
    returns(address);


    function token1()
    external
    view
    returns(address);

}



interface IERC20 {

    function transfer(
        address to,
        uint amount
    )
    external
    returns(bool);


    function balanceOf(
        address account
    )
    external
    view
    returns(uint);

}




contract FlashLoanAttacker {


    address public pair;


    address public owner;



    constructor(
        address _pair
    )
    {

        pair =
            _pair;

        owner =
            msg.sender;

    }






    function attackToken0(
        uint amount
    )
    external
    {

        IApexPair(pair)
        .swap(
            amount,
            0,
            address(this),
            abi.encode(
                uint8(0)
            )
        );

    }






    function attackToken1(
        uint amount
    )
    external
    {

        IApexPair(pair)
        .swap(
            0,
            amount,
            address(this),
            abi.encode(
                uint8(1)
            )
        );

    }








    function apexV2Call(
        address,
        uint amount0,
        uint amount1,
        bytes calldata
    )
    external
    {


        // Intentional attacker behavior:
        // no repayment


        if(amount0 > 0){

            address token0 =
                IApexPair(pair)
                .token0();


            IERC20(token0)
            .transfer(
                owner,
                amount0
            );

        }



        if(amount1 > 0){

            address token1 =
                IApexPair(pair)
                .token1();


            IERC20(token1)
            .transfer(
                owner,
                amount1
            );

        }


    }

}