// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/libraries/SafeTransfer.sol";
import "../src/contracts/test/MockERC20.sol";


contract SafeTransferHarness {

    using SafeTransfer for address;

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external
    {
        SafeTransfer.safeTransferFrom(
            token,
            from,
            to,
            amount
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    )
        external
    {
        SafeTransfer.safeTransfer(
            token,
            to,
            amount
        );
    }
}


contract FalseReturnToken {

    function transfer(
        address,
        uint256
    )
        external
        pure
        returns(bool)
    {
        return false;
    }

    function transferFrom(
        address,
        address,
        uint256
    )
        external
        pure
        returns(bool)
    {
        return false;
    }
}


contract NoReturnToken {

    function transfer(
        address,
        uint256
    )
        external
    {
    }

    function transferFrom(
        address,
        address,
        uint256
    )
        external
    {
    }
}


contract RevertingToken {

    function transfer(
        address,
        uint256
    )
        external
        pure
    {
        revert("TOKEN_REVERT");
    }

    function transferFrom(
        address,
        address,
        uint256
    )
        external
        pure
    {
        revert("TOKEN_REVERT");
    }
}


contract BadReturnToken {

    function transfer(
        address,
        uint256
    )
        external
        pure
    {
        assembly {
            mstore(0x00, 0x01)
            return(0x00, 1)
        }
    }

    function transferFrom(
        address,
        address,
        uint256
    )
        external
        pure
    {
        assembly {
            mstore(0x00, 0x01)
            return(0x00, 1)
        }
    }
}


contract SafeTransferTest is Test {

    SafeTransferHarness public harness;
    MockERC20 public token;

    address public alice;
    address public bob;

    uint256 constant AMOUNT = 100 ether;


    function setUp() public {

        harness = new SafeTransferHarness();

        token = new MockERC20(
            "Mock Token",
            "MOCK"
        );

        alice = address(0xA11CE);
        bob = address(0xB0B);

        token.mint(
            alice,
            AMOUNT
        );
    }


    // =============================================================
    // safeTransferFrom
    // =============================================================

    function testSafeTransferFromSuccess() public {

        vm.prank(alice);

        token.approve(
            address(harness),
            AMOUNT
        );

        harness.safeTransferFrom(
            address(token),
            alice,
            bob,
            AMOUNT
        );

        assertEq(
            token.balanceOf(alice),
            0
        );

        assertEq(
            token.balanceOf(bob),
            AMOUNT
        );
    }


    function testSafeTransferFromRevertsWhenTokenReverts() public {

        RevertingToken badToken =
            new RevertingToken();

        vm.expectRevert(
            "TRANSFER_FROM_FAILED"
        );

        harness.safeTransferFrom(
            address(badToken),
            alice,
            bob,
            AMOUNT
        );
    }


    function testSafeTransferFromRevertsOnFalseReturn() public {

        FalseReturnToken badToken =
            new FalseReturnToken();

        vm.expectRevert(
            "TRANSFER_FROM_FAILED"
        );

        harness.safeTransferFrom(
            address(badToken),
            alice,
            bob,
            AMOUNT
        );
    }


    function testSafeTransferFromAcceptsNoReturnData() public {

        NoReturnToken noReturnToken =
            new NoReturnToken();

        harness.safeTransferFrom(
            address(noReturnToken),
            alice,
            bob,
            AMOUNT
        );
    }


    function testSafeTransferFromRevertsOnBadReturnData() public {

        BadReturnToken badToken =
            new BadReturnToken();

        vm.expectRevert(
            "TRANSFER_FROM_FAILED"
        );

        harness.safeTransferFrom(
            address(badToken),
            alice,
            bob,
            AMOUNT
        );
    }


    // =============================================================
    // safeTransfer
    // =============================================================

    function testSafeTransferSuccess() public {

        vm.prank(alice);

        token.transfer(
            address(harness),
            AMOUNT
        );

        harness.safeTransfer(
            address(token),
            bob,
            AMOUNT
        );

        assertEq(
            token.balanceOf(bob),
            AMOUNT
        );
    }


    function testSafeTransferRevertsWhenTokenReverts() public {

        RevertingToken badToken =
            new RevertingToken();

        vm.expectRevert(
            "TRANSFER_FAILED"
        );

        harness.safeTransfer(
            address(badToken),
            bob,
            AMOUNT
        );
    }


    function testSafeTransferRevertsOnFalseReturn() public {

        FalseReturnToken badToken =
            new FalseReturnToken();

        vm.expectRevert(
            "TRANSFER_FAILED"
        );

        harness.safeTransfer(
            address(badToken),
            bob,
            AMOUNT
        );
    }


    function testSafeTransferAcceptsNoReturnData() public {

        NoReturnToken noReturnToken =
            new NoReturnToken();

        harness.safeTransfer(
            address(noReturnToken),
            bob,
            AMOUNT
        );
    }


    function testSafeTransferRevertsOnBadReturnData() public {

        BadReturnToken badToken =
            new BadReturnToken();

        vm.expectRevert(
            "TRANSFER_FAILED"
        );

        harness.safeTransfer(
            address(badToken),
            bob,
            AMOUNT
        );
    }
}