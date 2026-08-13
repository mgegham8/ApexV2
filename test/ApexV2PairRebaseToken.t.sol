// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/RebaseERC20.sol";

contract ApexV2PairRebaseTokenTest is Test {

    ApexV2Pair pair;

    RebaseERC20 token0;
    MockERC20 token1;

    function setUp() public {

        token0 = new RebaseERC20(
            "Rebase Token",
            "RBS"
        );

        token1 = new MockERC20(
            "Normal Token",
            "NORM"
        );

        pair = new ApexV2Pair();

        pair.initialize(
            address(token0),
            address(token1)
        );

        token0.mint(
            address(this),
            1000 ether
        );

        token1.mint(
            address(this),
            1000 ether
        );

        token0.transfer(
            address(pair),
            1000 ether
        );

        token1.transfer(
            address(pair),
            1000 ether
        );

        console2.log(
            "token0 pair balance",
            token0.balanceOf(address(pair))
        );

        console2.log(
            "token1 pair balance",
            token1.balanceOf(address(pair))
        );

        pair.mint(
            address(this)
        );

    }

    /// @notice Mock factory function required by ApexV2Pair during mint/swap fee checks
    function feeTo() external pure returns (address) {
        return address(0);
    }

    function testPositiveRebase()
        public
    {

        (
            uint112 reserve0,
            ,
        ) = pair.getReserves();

        console2.log(
            "reserve0 before",
            reserve0
        );

        token0.rebase(
            2e18
        );

        uint balance =
            token0.balanceOf(
                address(pair)
            );

        console2.log(
            "token0 after rebase",
            balance
        );

        assertGt(
            balance,
            reserve0
        );

        pair.sync();

        (
            uint112 newReserve0,
            ,
        ) = pair.getReserves();

        assertEq(
            newReserve0,
            balance
        );

    }

}