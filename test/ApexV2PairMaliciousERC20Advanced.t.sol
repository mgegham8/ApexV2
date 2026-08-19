// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract FalseReturnERC20 {
    string public name = "False Token";
    string public symbol = "FALSE";

    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        uint256 supply = 1_000_000 ether;

        balanceOf[msg.sender] = supply;
        totalSupply = supply;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;

        balanceOf[to] += amount;

        // malicious:
        // state changed but returns false
        return false;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        // malicious:
        // approval happened but returns false
        return false;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        require(allowed >= amount, "allowance");

        allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        balanceOf[to] += amount;

        // malicious:
        // transfer happened but returns false
        return false;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;

        totalSupply += amount;
    }
}
