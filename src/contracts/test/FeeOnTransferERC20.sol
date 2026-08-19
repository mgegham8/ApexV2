// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract FeeOnTransferERC20 {
    string public name = "Fee Token";

    string public symbol = "FEE";

    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    // Fee in basis points.
    // 100 = 1%, 10_000 = 100%.
    uint256 public immutable fee;

    address public immutable feeReceiver;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(uint256 _fee) {
        require(_fee <= 10_000, "FEE_TOO_HIGH");

        fee = _fee;

        feeReceiver = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(to != address(0), "ZERO_ADDRESS");

        balanceOf[to] += amount;

        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        require(allowed >= amount, "ALLOWANCE_LOW");

        if (allowed != type(uint256).max) {
            unchecked {
                allowance[from][msg.sender] = allowed - amount;
            }

            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }

        _transfer(from, to, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ZERO_ADDRESS");

        uint256 fromBalance = balanceOf[from];

        require(fromBalance >= amount, "BALANCE_LOW");

        uint256 tax = amount * fee / 10_000;

        uint256 sendAmount = amount - tax;

        unchecked {
            balanceOf[from] = fromBalance - amount;
        }

        balanceOf[to] += sendAmount;

        emit Transfer(from, to, sendAmount);

        if (tax != 0) {
            balanceOf[feeReceiver] += tax;

            emit Transfer(from, feeReceiver, tax);
        }
    }
}
