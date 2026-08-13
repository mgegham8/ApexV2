// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/launch/ApexVesting.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexVestingTest is Test {
    ApexVesting vesting;
    MockERC20 token;

    address user = address(0x1);
    address operator = address(0x2);

    uint256 startTimestamp;
    uint256 duration = 365 days;
    uint256 cliff = 30 days;
    uint256 totalAllocation = 1000e18;

    function setUp() public {
        token = new MockERC20("Apex Token", "APEX");
        
        vesting = new ApexVesting(address(token));
        
        vesting.setOperator(operator, true);

        token.mint(address(vesting), totalAllocation);
    }

    function testCliffPeriodNoClaim() public {
        startTimestamp = block.timestamp;

        vm.prank(operator);
        vesting.createVesting(user, totalAllocation, startTimestamp, cliff, duration);

        warp(startTimestamp + 15 days);

        vm.prank(user);
        vm.expectRevert("nothing");
        vesting.claim();
    }

    function testClaimAfterCliff() public {
        startTimestamp = block.timestamp;

        vm.prank(operator);
        vesting.createVesting(user, totalAllocation, startTimestamp, cliff, duration);

        skip(60 days);

        uint256 claimableBefore = vesting.claimable(user);
        assertTrue(claimableBefore > 0);

        vm.prank(user);
        vesting.claim();

        uint256 userBalance = token.balanceOf(user);
        assertTrue(userBalance > 0);
    }

    function testFullVestingComplete() public {
        startTimestamp = block.timestamp;

        vm.prank(operator);
        vesting.createVesting(user, totalAllocation, startTimestamp, cliff, duration);

        skip(365 days + 1);

        vm.prank(user);
        vesting.claim();

        assertEq(token.balanceOf(address(vesting)), 0);
        assertEq(token.balanceOf(user), totalAllocation);
    }

    function warp(uint256 timestamp) internal {
        vm.warp(timestamp);
    }
}