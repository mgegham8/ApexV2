// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract MockFeeToken {


    string public name = "Fee Token";
    string public symbol = "FEE";
    uint8 public decimals = 18;


    uint public totalSupply;


    mapping(address => uint) public balanceOf;

    mapping(address => mapping(address => uint))
        public allowance;



    event Transfer(
        address indexed from,
        address indexed to,
        uint value
    );


    event Approval(
        address indexed owner,
        address indexed spender,
        uint value
    );



    uint public constant FEE = 1;



    function mint(
        address to,
        uint amount
    )
        external
    {
        balanceOf[to] += amount;
        totalSupply += amount;

        emit Transfer(
            address(0),
            to,
            amount
        );
    }





    function approve(
        address spender,
        uint amount
    )
        external
        returns(bool)
    {

        allowance[msg.sender][spender] = amount;


        emit Approval(
            msg.sender,
            spender,
            amount
        );


        return true;
    }




    function transfer(
        address to,
        uint amount
    )
        external
        returns(bool)
    {

        uint feeAmount =
            amount * FEE / 100;


        uint sendAmount =
            amount - feeAmount;



        balanceOf[msg.sender] -= amount;

        balanceOf[to] += sendAmount;



        totalSupply -= feeAmount;



        emit Transfer(
            msg.sender,
            to,
            sendAmount
        );


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


        uint allowed =
            allowance[from][msg.sender];


        if(allowed != type(uint).max)
        {
            allowance[from][msg.sender] =
                allowed - amount;
        }



        uint feeAmount =
            amount * FEE / 100;


        uint sendAmount =
            amount - feeAmount;



        balanceOf[from] -= amount;

        balanceOf[to] += sendAmount;


        totalSupply -= feeAmount;



        emit Transfer(
            from,
            to,
            sendAmount
        );


        return true;
    }

}