// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

contract BadERC20 {
    string public name = "Bad Token";
    string public symbol = "BAD";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 ether;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        if (value == 999 ether) {
            return false;
        }
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return true;
    }
}

contract ApexV2ERC20EdgeCasesTest is Test {
    BadERC20 badToken;

    function setUp() public {
        badToken = new BadERC20();
    }

    function testBadTokenTransferReturnsFalse() public {
        address recipient = address(0x123);
        bool success = badToken.transfer(recipient, 999 ether);
        assertFalse(success, "Bad token did not return false");
    }
}