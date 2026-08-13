// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract FalseReturnERC20 {


    string public name = "False Return Token";
    string public symbol = "FALSE";
    uint8 public decimals = 18;


    uint public totalSupply;


    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;



    function mint(
        address to,
        uint amount
    )
    external
    {

        balanceOf[to] += amount;

        totalSupply += amount;

    }





    function approve(
        address spender,
        uint amount
    )
    external
    returns(bool)
    {

        allowance[msg.sender][spender] = amount;

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


        return false;

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


        return false;

    }


}