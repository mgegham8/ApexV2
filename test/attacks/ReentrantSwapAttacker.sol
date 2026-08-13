// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../../src/contracts/interfaces/IApexV2Callee.sol";
import "../../src/contracts/ApexV2Pair.sol";


contract ReentrantSwapAttacker is IApexV2Callee {

    ApexV2Pair public pair;

    bool public attacked;


    constructor(
        address _pair
    ){
        pair = ApexV2Pair(_pair);
    }



    function attack()
        external
    {

        pair.swap(
            1,
            0,
            address(this),
            abi.encode(
                true
            )
        );

    }



    function apexV2Call(
        address,
        uint amount0,
        uint amount1,
        bytes calldata
    )
        external
    {

        attacked = true;


        // attempt reentrancy

        pair.swap(
            1,
            0,
            address(this),
            ""
        );

    }

}