// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IController {

    function launch(
        address weth,
        uint tokenAmount,
        uint ethAmount
    )
    external
    payable;

}



contract MockReentrantRouter {


    address public controller;


    address public weth;


    uint public tokenAmount;


    uint public ethAmount;



    bool public attack;



    constructor(
        address _controller
    )
    {
        controller = _controller;
    }





    function setAttack(
        address _weth,
        uint _tokenAmount,
        uint _ethAmount
    )
    external
    {

        weth = _weth;

        tokenAmount = _tokenAmount;

        ethAmount = _ethAmount;

        attack = true;

    }







    function addLiquidity(
        address,
        address,
        uint,
        uint,
        uint,
        uint,
        address,
        uint
    )
    external
    payable
    returns(
        uint,
        uint,
        uint
    )
    {


        if(attack)
        {

            attack = false;


            IController(controller)
            .launch{value: ethAmount}(
                weth,
                tokenAmount,
                ethAmount
            );

        }




        return(
            0,
            0,
            1
        );


    }


}