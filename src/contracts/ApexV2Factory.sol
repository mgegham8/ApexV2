// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./ApexV2Pair.sol";

contract ApexV2Factory {

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;

    address[] public allPairs;


    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );


    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }



    function allPairsLength()
        external
        view
        returns(uint)
    {
        return allPairs.length;
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
        ) =
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


        pair = address(newPair);



        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;


        allPairs.push(pair);



        emit PairCreated(
            token0,
            token1,
            pair,
            allPairs.length
        );

    }




    function setFeeTo(
        address _feeTo
    )
        external
    {
        require(
            msg.sender == feeToSetter,
            "FORBIDDEN"
        );

        feeTo = _feeTo;
    }



    function setFeeToSetter(
        address _setter
    )
        external
    {
        require(
            msg.sender == feeToSetter,
            "FORBIDDEN"
        );

        feeToSetter = _setter;
    }

}