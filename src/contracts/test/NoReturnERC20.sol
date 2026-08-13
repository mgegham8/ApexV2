// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract NoReturnERC20 {


    string public name = "NoReturn Token";
    string public symbol = "NRT";

    uint8 public decimals = 18;


    uint public totalSupply;



    mapping(address => uint)
    public balanceOf;



    mapping(address => mapping(address => uint))
    public allowance;





    constructor()
    {
        _mint(
            msg.sender,
            1000000 ether
        );
    }







    function _mint(
        address to,
        uint amount
    )
    internal
    {

        balanceOf[to] += amount;

        totalSupply += amount;

    }









    function mint(
        address to,
        uint amount
    )
    external
    {

        _mint(
            to,
            amount
        );

    }









    function approve(
        address spender,
        uint amount
    )
    external
    {

        allowance[msg.sender][spender]
        =
        amount;


        // NO RETURN

    }









    function transfer(
        address to,
        uint amount
    )
    external
    {

        require(
            balanceOf[msg.sender] >= amount,
            "balance"
        );


        balanceOf[msg.sender]
        -= amount;


        balanceOf[to]
        += amount;


        // intentionally no return

    }









    function transferFrom(
        address from,
        address to,
        uint amount
    )
    external
    {

        require(
            balanceOf[from] >= amount,
            "balance"
        );


        require(
            allowance[from][msg.sender] >= amount,
            "allowance"
        );



        allowance[from][msg.sender]
        -= amount;



        balanceOf[from]
        -= amount;


        balanceOf[to]
        += amount;



        // intentionally no return

    }



}