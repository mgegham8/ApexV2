// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2RouterHandler is Test {
    ApexV2Router router;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;

    uint256 public swaps;
    uint256 public liquidityAdds;

    constructor(ApexV2Router _router, ApexV2Pair _pair, MockERC20 _token0, MockERC20 _token1) {
        router = _router;
        pair = _pair;
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(uint256 amount0, uint256 amount1) external {
        amount0 = bound(amount0, 1 ether, 1000 ether);
        amount1 = bound(amount1, 1 ether, 1000 ether);

        token0.mint(msg.sender, amount0);
        token1.mint(msg.sender, amount1);

        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);

        try router.addLiquidity(
            address(token0), address(token1), amount0, amount1, 0, 0, msg.sender, block.timestamp
        ) returns (
            uint256, uint256, uint256
        ) {
            liquidityAdds++;
        } catch {}
    }

    function swap(uint256 amount) external {
        amount = bound(amount, 0.1 ether, 10 ether);

        token0.mint(msg.sender, amount);
        token0.approve(address(router), amount);

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        try router.swapExactTokensForTokens(amount, 0, path, msg.sender, block.timestamp) returns (uint256[] memory) {
            swaps++;
        } catch {}
    }
}

contract ApexV2RouterInvariantTest is Test {
    ApexV2Factory factory;
    ApexV2Router router;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;
    MockERC20 weth;
    ApexV2RouterHandler handler;

    function setUp() public {
        // Ensure token0 address is strictly less than token1 address (Uniswap V2 requirement)
        MockERC20 tokenA = new MockERC20("Token0", "TK0");
        MockERC20 tokenB = new MockERC20("Token1", "TK1");
        if (address(tokenA) < address(tokenB)) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }

        weth = new MockERC20("WETH", "WETH");

        factory = new ApexV2Factory(address(this));

        address pairAddress = factory.createPair(address(token0), address(token1));
        pair = ApexV2Pair(pairAddress);

        router = new ApexV2Router(address(factory), address(weth));

        handler = new ApexV2RouterHandler(router, pair, token0, token1);

        targetContract(address(handler));
    }

    function invariant_reservesNeverExceedBalance() public view {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        assertLe(reserve0, token0.balanceOf(address(pair)));

        assertLe(reserve1, token1.balanceOf(address(pair)));
    }
}
