// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WETH9 {

    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;


    mapping(address => uint) public balanceOf;

    mapping(address => mapping(address => uint))
        public allowance;



    event Deposit(
        address indexed dst,
        uint wad
    );


    event Withdrawal(
        address indexed src,
        uint wad
    );


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



    receive()
    external
    payable
    {
        deposit();
    }



    function deposit()
    public
    payable
    {

        balanceOf[msg.sender] += msg.value;


        emit Deposit(
            msg.sender,
            msg.value
        );

    }



    function withdraw(
        uint wad
    )
    public
    {

        require(
            balanceOf[msg.sender] >= wad,
            "WETH: balance"
        );


        balanceOf[msg.sender] -= wad;


        payable(msg.sender)
        .transfer(wad);



        emit Withdrawal(
            msg.sender,
            wad
        );

    }



    function transfer(
        address to,
        uint value
    )
    public
    returns(bool)
    {

        require(
            balanceOf[msg.sender] >= value,
            "WETH: balance"
        );


        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;


        emit Transfer(
            msg.sender,
            to,
            value
        );


        return true;

    }




    function approve(
        address spender,
        uint value
    )
    public
    returns(bool)
    {

        allowance[msg.sender][spender] = value;


        emit Approval(
            msg.sender,
            spender,
            value
        );


        return true;

    }




    function transferFrom(
        address from,
        address to,
        uint value
    )
    public
    returns(bool)
    {


        require(
            balanceOf[from] >= value,
            "WETH: balance"
        );


        if(from != msg.sender){

            require(
                allowance[from][msg.sender] >= value,
                "WETH: allowance"
            );


            allowance[from][msg.sender] -= value;

        }


        balanceOf[from] -= value;
        balanceOf[to] += value;



        emit Transfer(
            from,
            to,
            value
        );


        return true;

    }

}