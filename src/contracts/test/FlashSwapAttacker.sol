// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IApexV2Callee {
    function apexV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}


interface IApexV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}



contract FlashSwapAttacker is IApexV2Callee {


    bool public attack;


    function execute(
        address pair,
        uint amount0,
        uint amount1
    )
    external
    {

        IApexV2Pair(pair).swap(
            amount0,
            amount1,
            address(this),
            abi.encode("attack")
        );

    }





    function apexV2Call(
        address,
        uint,
        uint,
        bytes calldata
    )
    external
    override
    {

        if(attack)
        {
            return;
        }


        // intentionally do not repay

    }



    function setAttack(
        bool value
    )
    external
    {
        attack = value;
    }

}