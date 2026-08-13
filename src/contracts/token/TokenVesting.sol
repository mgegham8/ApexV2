// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IERC20 {

    function transfer(
        address to,
        uint amount
    ) external returns(bool);


    function balanceOf(
        address account
    )
    external
    view
    returns(uint);

}



contract TokenVesting {


    error NotBeneficiary();

    error NothingToRelease();

    error TransferFailed();


    IERC20 public immutable token;


    address public immutable beneficiary;


    uint public immutable start;


    uint public immutable cliff;


    uint public immutable duration;


    uint public immutable totalAmount;


    uint public released;



    constructor(
        address _token,
        address _beneficiary,
        uint _start,
        uint _cliffDuration,
        uint _duration,
        uint _amount
    )
    {

        require(
            _token != address(0),
            "zero token"
        );


        require(
            _beneficiary != address(0),
            "zero beneficiary"
        );


        require(
            _duration > 0,
            "zero duration"
        );


        require(
            _cliffDuration <= _duration,
            "invalid cliff"
        );


        token =
            IERC20(_token);


        beneficiary =
            _beneficiary;


        start =
            _start;


        cliff =
            _start + _cliffDuration;


        duration =
            _duration;


        totalAmount =
            _amount;

    }





    function release()
        external
    {

        if(
            msg.sender != beneficiary
        )
        {
            revert NotBeneficiary();
        }



        uint amount =
            releasableAmount();



        if(amount == 0)
        {
            revert NothingToRelease();
        }



        released += amount;



        bool success =
            token.transfer(
                beneficiary,
                amount
            );


        if(!success)
        {
            revert TransferFailed();
        }

    }





    function releasableAmount()
        public
        view
        returns(uint)
    {

        return
            vestedAmount(
                block.timestamp
            )
            -
            released;

    }





    function vestedAmount(
        uint timestamp
    )
        public
        view
        returns(uint)
    {

        if(timestamp < cliff)
        {
            return 0;
        }



        if(timestamp >= start + duration)
        {
            return totalAmount;
        }



        return
            totalAmount *
            (timestamp - start)
            /
            duration;

    }

}