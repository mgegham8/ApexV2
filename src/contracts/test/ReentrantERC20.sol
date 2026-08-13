// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;


interface IRouterCallback {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
    external
    returns(
        uint amountA,
        uint amountB,
        uint liquidity
    );

}



contract ReentrantERC20 {


    string public name = "Reentrant Token";
    string public symbol = "REENT";

    uint8 public decimals = 18;


    uint public totalSupply;


    mapping(address => uint) 
    public balanceOf;


    mapping(address => mapping(address => uint))
    public allowance;



    address public router;
    address public tokenB;


    bool public attack;



    constructor(
        address _router
    ){

        router = _router;


        balanceOf[msg.sender] =
            1000000 ether;


        totalSupply =
            1000000 ether;

    }




    function setAttack(
        bool value,
        address _tokenB
    )
    external
    {

        attack = value;

        tokenB = _tokenB;

    }






    function approve(
        address spender,
        uint amount
    )
    external
    returns(bool)
    {

        allowance[msg.sender][spender] =
            amount;


        return true;

    }






    function transfer(
        address to,
        uint amount
    )
    external
    returns(bool)
    {


        balanceOf[msg.sender] -= amount;

        balanceOf[to] += amount;


        return true;

    }







    function transferFrom(
        address from,
        address to,
        uint amount
    )
    external
    returns(bool)
    {


        allowance[from][msg.sender] -= amount;



        balanceOf[from] -= amount;

        balanceOf[to] += amount;




        if(
            attack &&
            msg.sender == router
        ){

            // stop infinite recursion
            attack = false;



            IRouterCallback(router)
            .addLiquidity(

                address(this),

                tokenB,

                1 ether,

                1 ether,

                0,

                0,

                from,

                block.timestamp + 1000

            );

        }



        return true;

    }



}