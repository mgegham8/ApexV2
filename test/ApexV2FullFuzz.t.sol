// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2FullFuzzHandler is Test {
    ApexV2Router router;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;

    uint256 public actionCount;

    constructor(ApexV2Router _router, ApexV2Pair _pair, MockERC20 _token0, MockERC20 _token1) {
        router = _router;
        pair = _pair;
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(uint256 amount0, uint256 amount1) external {
        amount0 = bound(amount0, 100, 1000 ether);
        amount1 = bound(amount1, 100, 1000 ether);

        token0.mint(msg.sender, amount0);
        token1.mint(msg.sender, amount1);

        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);

        try router.addLiquidity(
            address(token0),
            address(token1),
            amount0,
            amount1,
            0,
            0,
            msg.sender,
            block.timestamp
        ) {
            actionCount++;
        } catch {}
    }

    function removeLiquidity(uint256 liquidityAmount) external {
        uint256 lpBal = pair.balanceOf(msg.sender);
        if (lpBal == 0) return;
        liquidityAmount = bound(liquidityAmount, 1, lpBal);

        pair.approve(address(router), liquidityAmount);

        try router.removeLiquidity(
            address(token0),
            address(token1),
            liquidityAmount,
            0,
            0,
            msg.sender,
            block.timestamp
        ) {
            actionCount++;
        } catch {}
    }

    function swap(uint256 amountIn, bool zeroToOne) external {
        amountIn = bound(amountIn, 10, 100 ether);

        MockERC20 inToken = zeroToOne ? token0 : token1;
        inToken.mint(msg.sender, amountIn);
        inToken.approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = zeroToOne ? address(token0) : address(token1);
        path[1] = zeroToOne ? address(token1) : address(token0);

        try router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            msg.sender,
            block.timestamp
        ) {
            actionCount++;
        } catch {}
    }

    function sync() external {
        try pair.sync() {
            actionCount++;
        } catch {}
    }

    function skim() external {
        try pair.skim(msg.sender) {
            actionCount++;
        } catch {}
    }

    function donate(uint256 amount) external {
        amount = bound(amount, 1, 10 ether);
        token0.mint(address(pair), amount);
        actionCount++;
    }
}

contract ApexV2FullFuzzTest is Test {
    ApexV2Factory factory;
    ApexV2Router router;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;
    MockERC20 weth;
    ApexV2FullFuzzHandler handler;

    function setUp() public {
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
        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));
        router = new ApexV2Router(address(factory), address(weth));

        handler = new ApexV2FullFuzzHandler(router, pair, token0, token1);

        targetContract(address(handler));
    }

    function invariant_reservesNeverExceedBalances() public view {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertLe(reserve0, token0.balanceOf(address(pair)), "Reserve 0 exceeds balance");
        assertLe(reserve1, token1.balanceOf(address(pair)), "Reserve 1 exceeds balance");
    }

    function invariant_totalSupplyValid() public view {
        uint256 totalSupply = pair.totalSupply();
        uint256 minLiq = 1000;
        if (totalSupply > 0) {
            assertTrue(totalSupply >= minLiq, "Total supply below minimum liquidity");
        }
    }
}