// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IApexReentrantRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

contract ReentrantERC20 {
    string public name = "Reentrant Token";

    string public symbol = "REENT";

    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    address public immutable router;

    address public tokenB;

    bool public attack;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(address _router) {
        require(_router != address(0), "ZERO_ROUTER");

        router = _router;

        _mint(msg.sender, 1_000_000 ether);
    }

    function setAttack(bool value, address _tokenB) external {
        attack = value;

        tokenB = _tokenB;
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

        /*
         * Intentional reentrancy attempt.
         *
         * Trigger only when Router itself calls transferFrom().
         * Clear attack first to prevent infinite recursion.
         */
        if (attack && msg.sender == router) {
            attack = false;

            IApexReentrantRouter(router)
                .addLiquidity(address(this), tokenB, 1 ether, 1 ether, 0, 0, from, block.timestamp + 1000);
        }

        return true;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ZERO_ADDRESS");

        balanceOf[to] += amount;

        totalSupply += amount;

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
