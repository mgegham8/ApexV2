// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/test/FeeOnTransferERC20.sol";


contract ApexV2RouterFeeOnTransferERC20SecurityTest is Test {


    FeeOnTransferERC20 public token;


    address alice = address(1);
    address bob = address(2);



    function setUp() public {

        token =
            new FeeOnTransferERC20(
                100
            ); // 1%


        token.mint(
            alice,
            1000 ether
        );
    }





    function testTransferFeeAccounting()
        public
    {

        vm.prank(alice);


        token.transfer(
            bob,
            100 ether
        );



        assertEq(
            token.balanceOf(bob),
            99 ether
        );


        assertEq(
            token.balanceOf(address(this)),
            1 ether
        );


        assertEq(
            token.balanceOf(alice),
            900 ether
        );

    }





    function testZeroFeeTransfer()
        public
    {

        FeeOnTransferERC20 zeroFee =
            new FeeOnTransferERC20(0);



        zeroFee.mint(
            alice,
            100 ether
        );



        vm.prank(alice);


        zeroFee.transfer(
            bob,
            100 ether
        );



        assertEq(
            zeroFee.balanceOf(bob),
            100 ether
        );


        assertEq(
            zeroFee.totalSupply(),
            100 ether
        );
    }






    function testHighFeeTransfer()
        public
    {

        FeeOnTransferERC20 highFee =
            new FeeOnTransferERC20(
                1000
            );


        highFee.mint(
            alice,
            100 ether
        );



        vm.prank(alice);


        highFee.transfer(
            bob,
            100 ether
        );



        assertEq(
            highFee.balanceOf(bob),
            90 ether
        );


        assertEq(
            highFee.balanceOf(address(this)),
            10 ether
        );

    }







    function testFeeDoesNotChangeTotalSupply()
        public
    {

        uint beforeSupply =
            token.totalSupply();



        vm.prank(alice);


        token.transfer(
            bob,
            100 ether
        );



        assertEq(
            token.totalSupply(),
            beforeSupply
        );
    }







   function testMultipleTransfersKeepAccounting()
    public
{

    vm.prank(alice);

    token.transfer(
        bob,
        100 ether
    );



    vm.prank(bob);

    token.transfer(
        alice,
        50 ether
    );



    // Bob:
    // received 99 ether
    // sent 50 ether
    // remaining = 49 ether

    assertEq(
        token.balanceOf(bob),
        49 ether
    );



    // Alice:
    // started 1000 ether
    // sent 100 ether
    // received 49.5 ether
    // remaining = 949.5 ether

    assertEq(
        token.balanceOf(alice),
        949.5 ether
    );



    // Fee receiver:
    // first transfer fee = 1 ether
    // second transfer fee = 0.5 ether
    // total = 1.5 ether

    assertEq(
        token.balanceOf(address(this)),
        1.5 ether
    );

}




    function testSenderCannotTransferMoreThanBalance()
        public
    {

        vm.prank(alice);


        vm.expectRevert();


        token.transfer(
            bob,
            2000 ether
        );

    }







    function testTotalSupplyInvariantAfterManyTransfers()
        public
    {

        uint supply =
            token.totalSupply();



        vm.startPrank(alice);


        token.transfer(
            bob,
            100 ether
        );


        vm.stopPrank();



        vm.prank(bob);


        token.transfer(
            alice,
            20 ether
        );



        assertEq(
            token.totalSupply(),
            supply
        );

    }

}