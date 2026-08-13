// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract FeeOnTransferERC20 {


    string public name = "Fee Token";
    string public symbol = "FEE";
    uint8 public decimals = 18;


    uint public totalSupply;


    uint public fee;


    address public feeReceiver;



    mapping(address=>uint) public balanceOf;



    constructor(
        uint _fee
    )
    {

        fee = _fee;

        feeReceiver =
            msg.sender;

    }





    function mint(
        address to,
        uint amount
    )
    external
    {

        balanceOf[to] += amount;

        totalSupply += amount;

    }






    function transfer(
        address to,
        uint amount
    )
    external
    returns(bool)
    {


        uint tax =
            amount * fee / 10000;



        uint sendAmount =
            amount - tax;



        balanceOf[msg.sender] -= amount;


        balanceOf[to] += sendAmount;


        balanceOf[feeReceiver] += tax;



        return true;

    }



}