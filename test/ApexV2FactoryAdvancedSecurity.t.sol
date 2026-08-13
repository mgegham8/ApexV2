// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";


contract ApexV2FactoryAdvancedSecurityTest is Test {


    ApexV2Factory factory;

    MockERC20 tokenA;
    MockERC20 tokenB;
    MockERC20 tokenC;



    function setUp()
    public
    {
        factory = new ApexV2Factory(
            address(this)
        );


        tokenA = new MockERC20(
            "Token A",
            "TKA"
        );


        tokenB = new MockERC20(
            "Token B",
            "TKB"
        );


        tokenC = new MockERC20(
            "Token C",
            "TKC"
        );
    }




   function testPairCreatedEvent()
public
{
    vm.recordLogs();


    address pair =
        factory.createPair(
            address(tokenA),
            address(tokenB)
        );


    Vm.Log[] memory logs =
        vm.getRecordedLogs();


    bool found = false;


    for(uint i = 0; i < logs.length; i++)
    {
        if(
            logs[i].topics[0] ==
            keccak256(
                "PairCreated(address,address,address,uint256)"
            )
        )
        {
            found = true;


            address createdPair;
            uint256 length;


            (
                createdPair,
                length
            ) =
                abi.decode(
                    logs[i].data,
                    (address,uint256)
                );


            assertEq(
                createdPair,
                pair
            );


            assertEq(
                length,
                1
            );


            assertEq(
                address(uint160(uint256(logs[i].topics[1]))),
                address(tokenA)
            );


            assertEq(
                address(uint160(uint256(logs[i].topics[2]))),
                address(tokenB)
            );
        }
    }


    assertTrue(found);
}



    function testAllPairsLengthIncreases()
    public
    {

        assertEq(
            factory.allPairsLength(),
            0
        );


        factory.createPair(
            address(tokenA),
            address(tokenB)
        );


        assertEq(
            factory.allPairsLength(),
            1
        );


        factory.createPair(
            address(tokenA),
            address(tokenC)
        );


        assertEq(
            factory.allPairsLength(),
            2
        );
    }





    function testDifferentPairsHaveDifferentAddresses()
    public
    {

        address pair1 =
            factory.createPair(
                address(tokenA),
                address(tokenB)
            );


        address pair2 =
            factory.createPair(
                address(tokenA),
                address(tokenC)
            );


        assertTrue(
            pair1 != pair2
        );
    }





    function testInitializeCannotBeCalledByAttacker()
    public
    {

        address pair =
            factory.createPair(
                address(tokenA),
                address(tokenB)
            );


        ApexV2Pair p =
            ApexV2Pair(pair);



        vm.expectRevert();


        p.initialize(
            address(tokenC),
            address(tokenA)
        );
    }





    function testPairStoredInAllPairs()
    public
    {

        address pair =
            factory.createPair(
                address(tokenA),
                address(tokenB)
            );


        assertEq(
            factory.allPairs(0),
            pair
        );
    }





    function testReverseLookupReturnsSamePair()
    public
    {

        address pair =
            factory.createPair(
                address(tokenB),
                address(tokenA)
            );


        assertEq(
            factory.getPair(
                address(tokenA),
                address(tokenB)
            ),
            pair
        );


        assertEq(
            factory.getPair(
                address(tokenB),
                address(tokenA)
            ),
            pair
        );
    }

}