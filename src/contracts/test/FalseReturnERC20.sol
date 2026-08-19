// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract FalseReturnERC20 {
    string public name = "False Return Token";

    string public symbol = "FALSE";

    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;

        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;

        balanceOf[to] += amount;

        return false;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;

        balanceOf[from] -= amount;

        balanceOf[to] += amount;

        return false;
    }
}
