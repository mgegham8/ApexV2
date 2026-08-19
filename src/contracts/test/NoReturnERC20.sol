// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract NoReturnERC20 {
    string public name = "NoReturn Token";

    string public symbol = "NRT";

    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _mint(msg.sender, 1_000_000 ether);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function approve(address spender, uint256 amount) external {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        // Intentionally no return value.
    }

    function transfer(address to, uint256 amount) external {
        _transfer(msg.sender, to, amount);

        // Intentionally no return value.
    }

    function transferFrom(address from, address to, uint256 amount) external {
        uint256 allowed = allowance[from][msg.sender];

        require(allowed >= amount, "ALLOWANCE_LOW");

        if (allowed != type(uint256).max) {
            unchecked {
                allowance[from][msg.sender] = allowed - amount;
            }

            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }

        _transfer(from, to, amount);

        // Intentionally no return value.
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ZERO_ADDRESS");

        totalSupply += amount;

        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ZERO_ADDRESS");

        uint256 balance = balanceOf[from];

        require(balance >= amount, "BALANCE_LOW");

        unchecked {
            balanceOf[from] = balance - amount;
        }

        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }
}
