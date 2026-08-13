// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ApexV2ERC20.sol";


contract TestPermitToken is ApexV2ERC20 {


    constructor()
    {

    }


    function mint(
        address to,
        uint amount
    )
    external
    {
        _mint(
            to,
            amount
        );
    }

}