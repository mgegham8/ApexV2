// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "../../src/contracts/interfaces/IApexV2Callee.sol";
import "../../src/contracts/interfaces/IApexV2Pair.sol";
import "../../src/contracts/interfaces/IERC20.sol";



contract FlashSwapAttacker is IApexV2Callee {


    address public pair;

    bool public repay;



    constructor(
        address _pair
    )
    {
        pair = _pair;
    }



    function setRepay(
        bool value
    )
    external
    {
        repay = value;
    }



    function attack(
        uint amount0,
        uint amount1
    )
    external
    {

        IApexV2Pair(pair)
        .swap(
            amount0,
            amount1,
            address(this),
            abi.encode(true)
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

        // Եթե false է՝ դիտավորյալ չենք վերադարձնում
        // Test-ը պետք է ստուգի, որ Pair-ը revert է անում
        if(!repay)
        {
            return;
        }



        address token0 =
            IApexV2Pair(pair)
            .token0();



        address token1 =
            IApexV2Pair(pair)
            .token1();




        // Flash swap repayment + 0.3% fee

        if(amount0 > 0)
        {

            uint repayAmount =
                (amount0 * 1000) / 997 + 1;


            IERC20(token0)
            .transfer(
                pair,
                repayAmount
            );

        }




        if(amount1 > 0)
        {

            uint repayAmount =
                (amount1 * 1000) / 997 + 1;


            IERC20(token1)
            .transfer(
                pair,
                repayAmount
            );

        }

    }

}