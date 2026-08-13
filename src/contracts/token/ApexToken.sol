// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


contract ApexToken is
    ERC20,
    ERC20Burnable,
    ERC20Permit,
    Ownable2Step,
    Pausable
{


    uint256 public constant MAX_SUPPLY =
        1_000_000_000 ether;



    uint256 public constant LIQUIDITY_ALLOCATION =
        200_000_000 ether;


    uint256 public constant COMMUNITY_ALLOCATION =
        250_000_000 ether;


    uint256 public constant TREASURY_ALLOCATION =
        200_000_000 ether;


    uint256 public constant TEAM_ALLOCATION =
        150_000_000 ether;


    uint256 public constant MARKETING_ALLOCATION =
        100_000_000 ether;


    uint256 public constant RESERVE_ALLOCATION =
        100_000_000 ether;



    constructor(
        address liquidity,
        address community,
        address treasury,
        address team,
        address marketing,
        address reserve
    )
        ERC20(
            "Apex Token",
            "APEX"
        )
        ERC20Permit(
            "Apex Token"
        )
        Ownable(
            msg.sender
        )
    {


        require(
            liquidity != address(0) &&
            community != address(0) &&
            treasury != address(0) &&
            team != address(0) &&
            marketing != address(0) &&
            reserve != address(0),
            "zero address"
        );



        _mint(
            liquidity,
            LIQUIDITY_ALLOCATION
        );


        _mint(
            community,
            COMMUNITY_ALLOCATION
        );


        _mint(
            treasury,
            TREASURY_ALLOCATION
        );


        _mint(
            team,
            TEAM_ALLOCATION
        );


        _mint(
            marketing,
            MARKETING_ALLOCATION
        );


        _mint(
            reserve,
            RESERVE_ALLOCATION
        );


    }





    function pause()
        external
        onlyOwner
    {
        _pause();
    }





    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }





    function _update(
        address from,
        address to,
        uint256 value
    )
        internal
        override
    {

        require(
            !paused(),
            "Token paused"
        );


        super._update(
            from,
            to,
            value
        );

    }


}