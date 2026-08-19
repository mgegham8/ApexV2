// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract MaliciousFactory {
    address public immutable fakePair;

    constructor(
        address _fakePair
    ) {
        fakePair =
            _fakePair;
    }

    function getPair(
        address,
        address
    )
        external
        view
        returns (address)
    {
        return fakePair;
    }

    function createPair(
        address,
        address
    )
        external
        view
        returns (address)
    {
        return fakePair;
    }
}