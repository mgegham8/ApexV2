// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../ApexV2Pair.sol";


contract MockFactory {

    address public feeReceiver;


    mapping(address => mapping(address => address)) public getPair;



    constructor()
    {
        feeReceiver = address(0);
    }



    function feeTo()
        external
        view
        returns(address)
    {
        return feeReceiver;
    }



    function setFeeTo(
        address _fee
    )
        external
    {
        feeReceiver = _fee;
    }



    function createPair(
        address tokenA,
        address tokenB
    )
        external
        returns(address pair)
    {

        require(
            tokenA != tokenB,
            "IDENTICAL_ADDRESSES"
        );


        require(
            tokenA != address(0) &&
            tokenB != address(0),
            "ZERO_ADDRESS"
        );



        (
            address token0,
            address token1
        )
        =
        tokenA < tokenB
        ?
        (tokenA, tokenB)
        :
        (tokenB, tokenA);



        require(
            getPair[token0][token1] == address(0),
            "PAIR_EXISTS"
        );



        ApexV2Pair newPair =
            new ApexV2Pair();



        newPair.initialize(
            token0,
            token1
        );



        pair =
            address(newPair);



        getPair[token0][token1] =
            pair;


        getPair[token1][token0] =
            pair;

    }

}