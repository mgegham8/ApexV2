// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IFakePair {
    function mint(address to) external returns(uint);
}


contract MaliciousFactory {


    address public fakePair;


    constructor(
        address _fakePair
    ){
        fakePair = _fakePair;
    }



    function getPair(
        address,
        address
    )
    external
    view
    returns(address)
    {
        return fakePair;
    }




    function createPair(
        address,
        address
    )
    external
    view
    returns(address)
    {
        return fakePair;
    }

}