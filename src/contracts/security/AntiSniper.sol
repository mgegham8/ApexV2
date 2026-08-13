// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract AntiSniper {


    address public owner;


    bool public protectionEnabled;


    uint256 public launchBlock;


    uint256 public protectionBlocks;


    uint256 public maxBuyAmount;


    uint256 public maxWalletAmount;



    mapping(address => bool) public whitelist;


    mapping(address => bool) public blacklist;



    mapping(address => uint256) public walletBought;



    event LaunchStarted(
        uint256 blockNumber
    );


    event ProtectionDisabled();


    event BlacklistUpdated(
        address indexed account,
        bool status
    );


    event WhitelistUpdated(
        address indexed account,
        bool status
    );



    event LimitsUpdated(
        uint256 maxBuy,
        uint256 maxWallet
    );






    modifier onlyOwner(){

        require(
            msg.sender == owner,
            "not owner"
        );

        _;

    }







    constructor(){

        owner =
            msg.sender;


        protectionEnabled =
            false;

    }








    function startLaunch(
        uint256 _protectionBlocks,
        uint256 _maxBuyAmount,
        uint256 _maxWalletAmount
    )
    external
    onlyOwner
    {


        require(
            !protectionEnabled,
            "already started"
        );



        launchBlock =
            block.number;



        protectionBlocks =
            _protectionBlocks;



        maxBuyAmount =
            _maxBuyAmount;



        maxWalletAmount =
            _maxWalletAmount;



        protectionEnabled =
            true;



        emit LaunchStarted(
            launchBlock
        );

    }









    function disableProtection()
    external
    onlyOwner
    {

        protectionEnabled =
            false;


        emit ProtectionDisabled();

    }









    function setBlacklist(
        address account,
        bool status
    )
    external
    onlyOwner
    {


        blacklist[account] =
            status;


        emit BlacklistUpdated(
            account,
            status
        );

    }









    function setWhitelist(
        address account,
        bool status
    )
    external
    onlyOwner
    {


        whitelist[account] =
            status;


        emit WhitelistUpdated(
            account,
            status
        );

    }









    function setLimits(
        uint256 _maxBuyAmount,
        uint256 _maxWalletAmount
    )
    external
    onlyOwner
    {

        maxBuyAmount =
            _maxBuyAmount;


        maxWalletAmount =
            _maxWalletAmount;


        emit LimitsUpdated(
            _maxBuyAmount,
            _maxWalletAmount
        );

    }









    function checkBuy(
        address buyer,
        uint256 amount,
        uint256 currentWalletBalance
    )
    external
    view
    returns(bool)
    {


        if(!protectionEnabled)
        {
            return true;
        }



        if(
            whitelist[buyer]
        )
        {
            return true;
        }




        require(
            !blacklist[buyer],
            "blacklisted"
        );




        require(
            block.number <=
            launchBlock + protectionBlocks,
            "protection ended"
        );




        require(
            amount <= maxBuyAmount,
            "max buy exceeded"
        );




        require(
            currentWalletBalance + amount
            <= maxWalletAmount,
            "max wallet exceeded"
        );



        return true;

    }






    function transferOwnership(
        address newOwner
    )
    external
    onlyOwner
    {

        require(
            newOwner != address(0),
            "zero address"
        );


        owner =
            newOwner;

    }



}