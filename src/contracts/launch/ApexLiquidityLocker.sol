// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IERC20 {

    function transfer(
        address to,
        uint amount
    ) external returns(bool);


    function transferFrom(
        address from,
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



contract ApexLiquidityLocker {


    error NotOwner();

    error Locked();

    error NotUnlocked();

    error AlreadyLocked();

    error TransferFailed();



    address public immutable owner;


    IERC20 public immutable lpToken;



    uint public unlockTime;


    uint public lockedAmount;


    bool public locked;




    constructor(
        address _lpToken
    )
    {

        require(
            _lpToken != address(0),
            "zero lp"
        );


        owner =
            msg.sender;


        lpToken =
            IERC20(_lpToken);

    }






    modifier onlyOwner()
    {

        if(
            msg.sender != owner
        )
        {
            revert NotOwner();
        }


        _;

    }







    function lock(
        uint amount,
        uint _unlockTime
    )
        external
        onlyOwner
    {

        if(locked)
        {
            revert AlreadyLocked();
        }



        require(
            amount > 0,
            "zero amount"
        );


        require(
            _unlockTime > block.timestamp,
            "invalid time"
        );



        bool success =
            lpToken.transferFrom(
                msg.sender,
                address(this),
                amount
            );


        if(!success)
        {
            revert TransferFailed();
        }



        lockedAmount =
            amount;


        unlockTime =
            _unlockTime;


        locked =
            true;

    }








    function withdraw()
        external
        onlyOwner
    {

        if(!locked)
        {
            revert Locked();
        }



        if(
            block.timestamp <
            unlockTime
        )
        {
            revert NotUnlocked();
        }




        uint amount =
            lockedAmount;



        lockedAmount = 0;


        locked = false;



        bool success =
            lpToken.transfer(
                owner,
                amount
            );



        if(!success)
        {
            revert TransferFailed();
        }

    }







    function getLockedAmount()
        external
        view
        returns(uint)
    {

        return lockedAmount;

    }


}