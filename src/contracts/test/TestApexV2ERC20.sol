// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../ApexV2ERC20.sol";

contract TestApexV2ERC20 is ApexV2ERC20 {
    function mint(
        address to,
        uint256 amount
    )
        external
    {
        _mint(
            to,
            amount
        );
    }

    function burn(
        uint256 amount
    )
        external
    {
        _burn(
            msg.sender,
            amount
        );
    }

    function transferInternal(
        address from,
        address to,
        uint256 amount
    )
        external
    {
        _transfer(
            from,
            to,
            amount
        );
    }
}