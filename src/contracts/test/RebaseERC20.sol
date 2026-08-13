// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract RebaseERC20 {

    string public name;
    string public symbol;

    uint8 public decimals = 18;


    uint internal constant BASE = 1e18;


    uint public totalShares;

    uint public multiplier = BASE;


    mapping(address => uint) internal shares;


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



    constructor(
        string memory _name,
        string memory _symbol
    )
    {
        name = _name;
        symbol = _symbol;
    }




    function totalSupply()
        public
        view
        returns(uint)
    {
        return
            totalShares
            *
            multiplier
            /
            BASE;
    }




    function balanceOf(
        address user
    )
        public
        view
        returns(uint)
    {
        return
            shares[user]
            *
            multiplier
            /
            BASE;
    }




    function mint(
        address to,
        uint amount
    )
        external
    {

        uint shareAmount =
            amount
            *
            BASE
            /
            multiplier;


        shares[to] += shareAmount;

        totalShares += shareAmount;


        emit Transfer(
            address(0),
            to,
            amount
        );
    }




    function transfer(
        address to,
        uint amount
    )
        external
        returns(bool)
    {

        uint shareAmount =
            amount
            *
            BASE
            /
            multiplier;


        require(
            shares[msg.sender] >= shareAmount,
            "BALANCE"
        );


        shares[msg.sender]
            -= shareAmount;


        shares[to]
            += shareAmount;


        emit Transfer(
            msg.sender,
            to,
            amount
        );


        return true;
    }





    function approve(
        address spender,
        uint amount
    )
        external
        returns(bool)
    {

        allowance[msg.sender][spender]
            = amount;


        emit Approval(
            msg.sender,
            spender,
            amount
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


        require(
            allowed >= amount,
            "ALLOWANCE"
        );


        if(
            allowed != type(uint).max
        )
        {
            allowance[from][msg.sender]
                =
                allowed - amount;
        }



        uint shareAmount =
            amount
            *
            BASE
            /
            multiplier;



        require(
            shares[from] >= shareAmount,
            "BALANCE"
        );


        shares[from]
            -= shareAmount;


        shares[to]
            += shareAmount;



        emit Transfer(
            from,
            to,
            amount
        );


        return true;
    }





    function rebase(
        uint newMultiplier
    )
        external
    {

        require(
            newMultiplier > 0,
            "ZERO"
        );


        multiplier = newMultiplier;
    }

}