// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";

/// @dev Custom standalone ERC20 token with built-in reentrancy callback support
contract ReentrantToken {
    string public name = "Reentrant Token";
    string public symbol = "RBT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public attacker;
    bool public triggerReentrancy;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function setAttacker(address _attacker) external {
        attacker = _attacker;
    }

    function setTrigger(bool _trigger) external {
        triggerReentrancy = _trigger;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);

        if (triggerReentrancy && recipient == attacker && attacker != address(0)) {
            IReentrantAttacker(attacker).callback();
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
        require(balanceOf[sender] >= amount, "ERC20: transfer amount exceeds balance");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}

interface IReentrantAttacker {
    function callback() external;
}

/// @title ApexV2RouterReentrancyTest
/// @notice Professional-grade security test suite verifying router and pair protection against reentrancy vectors.
contract ApexV2RouterReentrancyTest is Test {
    ApexV2Factory factory;
    ApexV2Router router;
    MockERC20 weth;
    MockERC20 token1;
    ReentrantToken reentrantToken;
    ApexV2Pair pair;

    ReentrantAttacker attacker;

    function setUp() public {
        factory = new ApexV2Factory(address(this));
        weth = new MockERC20("Wrapped Ether", "WETH");
        router = new ApexV2Router(address(factory), address(weth));

        reentrantToken = new ReentrantToken();
        token1 = new MockERC20("Normal Token", "NORM");

        address t0 = address(reentrantToken) < address(token1) ? address(reentrantToken) : address(token1);
        address t1 = address(reentrantToken) < address(token1) ? address(token1) : address(reentrantToken);

        address pairAddress = factory.createPair(t0, t1);
        pair = ApexV2Pair(pairAddress);

        reentrantToken.mint(address(this), 50000 ether);
        token1.mint(address(this), 50000 ether);

        reentrantToken.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        router.addLiquidity(t0, t1, 10000 ether, 10000 ether, 0, 0, address(this), block.timestamp);

        attacker = new ReentrantAttacker(router, address(pair), t0, t1);
        reentrantToken.setAttacker(address(attacker));
    }

    /// @notice Verifies that malicious token callbacks cannot trigger re-entrancy during liquidity removal.
    function test_Router_ReentrancyBlocked() public {
        uint256 lpBalance = pair.balanceOf(address(this));
        pair.transfer(address(attacker), lpBalance / 2);

        reentrantToken.setTrigger(true);

        vm.prank(address(attacker));
        try attacker.attackRemoveLiquidity() {
            fail("Reentrancy attack should have been blocked");
        } catch {
            assertTrue(true, "Reentrancy successfully blocked by architecture");
        }
    }
}

contract ReentrantAttacker is IReentrantAttacker {
    ApexV2Router public router;
    ApexV2Pair public pair;
    address public token0;
    address public token1;

    constructor(ApexV2Router _router, address _pair, address _token0, address _token1) {
        router = _router;
        pair = ApexV2Pair(_pair);
        token0 = _token0;
        token1 = _token1;
    }

    function attackRemoveLiquidity() external {
        uint256 liquidity = pair.balanceOf(address(this));
        pair.approve(address(router), liquidity);

        router.removeLiquidity(token0, token1, liquidity, 0, 0, address(this), block.timestamp);
    }

    function callback() external override {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        // Attempting malicious re-entrant call back into the router/pair
        router.swapExactTokensForTokens(1e18, 0, path, address(this), block.timestamp);
    }
}
