// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract MaliciousERC20 {


    string public name = "Malicious";
    string public symbol = "BAD";

    uint8 public decimals = 18;


    uint public totalSupply;


    mapping(address => uint)
    public balanceOf;


    mapping(address => mapping(address => uint))
    public allowance;



    bool public failTransferFrom;

    bool public failTransfer;

    bool public revertTransferFrom;

    bool public revertTransfer;



    constructor(){

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








    function approve(
        address spender,
        uint amount
    )
    external
    returns(bool)
    {


        allowance[msg.sender][spender]
        =
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


        if(revertTransfer)
        {
            revert(
                "MALICIOUS_TRANSFER_REVERT"
            );
        }



        if(failTransfer)
        {
            return false;
        }



        require(
            balanceOf[msg.sender] >= amount,
            "INSUFFICIENT_BALANCE"
        );



        balanceOf[msg.sender]
        -= amount;


        balanceOf[to]
        += amount;



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


        if(revertTransferFrom)
        {
            revert(
                "MALICIOUS_TRANSFERFROM_REVERT"
            );
        }




        if(failTransferFrom)
        {
            return false;
        }




        require(
            allowance[from][msg.sender] >= amount,
            "INSUFFICIENT_ALLOWANCE"
        );



        require(
            balanceOf[from] >= amount,
            "INSUFFICIENT_BALANCE"
        );




        allowance[from][msg.sender]
        -= amount;



        balanceOf[from]
        -= amount;



        balanceOf[to]
        += amount;




        return true;

    }









    function setFailTransferFrom(
        bool value
    )
    external
    {

        failTransferFrom = value;

    }








    function setFailTransfer(
        bool value
    )
    external
    {

        failTransfer = value;

    }







    function setRevertTransferFrom(
        bool value
    )
    external
    {

        revertTransferFrom = value;

    }







    function setRevertTransfer(
        bool value
    )
    external
    {

        revertTransfer = value;

    }



}