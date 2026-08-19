// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2SwapFuzzHandler is Test {
    ApexV2Router router;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;

    uint256 public successfulSwaps;

    constructor(ApexV2Router _router, ApexV2Pair _pair, MockERC20 _token0, MockERC20 _token1) {
        router = _router;
        pair = _pair;
        token0 = _token0;
        token1 = _token1;
    }

    function fuzzSwap(uint256 amountIn, bool zeroToOne) external {
        amountIn = bound(amountIn, 1e15, 50 ether); // 0.001 to 50 tokens

        MockERC20 inToken = zeroToOne ? token0 : token1;
        inToken.mint(msg.sender, amountIn);
        inToken.approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = zeroToOne ? address(token0) : address(token1);
        path[1] = zeroToOne ? address(token1) : address(token0);

        try router.swapExactTokensForTokens(amountIn, 0, path, msg.sender, block.timestamp) returns (uint256[] memory) {
            successfulSwaps++;
        } catch {}
    }
}

contract ApexV2SwapFuzzTest is Test {
    ApexV2Factory factory;
    ApexV2Router router;
    ApexV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;
    MockERC20 weth;
    ApexV2SwapFuzzHandler handler;

    uint256 initialK;

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

        // Seed initial deep liquidity to prevent extreme price impact overflows during fuzzing
        token0.mint(address(this), 10000 ether);
        token1.mint(address(this), 10000 ether);
        token0.transfer(address(pair), 10000 ether);
        token1.transfer(address(pair), 10000 ether);
        pair.mint(address(this));

        (uint112 r0, uint112 r1,) = pair.getReserves();
        initialK = uint256(r0) * uint256(r1);

        handler = new ApexV2SwapFuzzHandler(router, pair, token0, token1);
        targetContract(address(handler));
    }

    function invariant_kNeverDecreasesWithTolerance() public view {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 currentK = uint256(r0) * uint256(r1);

        // K can increase due to swap fees, but should never decrease below initial K
        assertTrue(currentK >= initialK, "Invariant K decreased below initial K");
    }

    function invariant_reservesMatchBalances() public view {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertLe(r0, token0.balanceOf(address(pair)), "Reserve 0 exceeds balance");
        assertLe(r1, token1.balanceOf(address(pair)), "Reserve 1 exceeds balance");
    }
}
