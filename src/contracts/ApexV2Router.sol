// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IApexV2Factory.sol";
import "./interfaces/IApexV2Pair.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH9.sol";
import "./libraries/ApexV2Library.sol";

contract ApexV2Router {
    address public immutable factory;
    address public immutable WETH;

    modifier ensure(uint deadline) {
        require(
            deadline >= block.timestamp,
            "ApexV2Router: EXPIRED"
        );
        _;
    }

    constructor(
        address _factory,
        address _WETH
    ) {
        require(
            _factory != address(0),
            "ApexV2Router: ZERO_FACTORY"
        );

        require(
            _WETH != address(0),
            "ApexV2Router: ZERO_WETH"
        );

        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        require(
            msg.sender == WETH,
            "ApexV2Router: ONLY_WETH"
        );
    }

    // ============================================================
    // ADD LIQUIDITY
    // ============================================================

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        ensure(deadline)
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        )
    {
        require(
            tokenA != tokenB,
            "ApexV2Router: IDENTICAL_TOKEN"
        );

        require(
            tokenA != address(0) &&
            tokenB != address(0),
            "ApexV2Router: ZERO_ADDRESS"
        );

        address pair =
            IApexV2Factory(factory).getPair(
                tokenA,
                tokenB
            );

        if (pair == address(0)) {
            pair =
                IApexV2Factory(factory).createPair(
                    tokenA,
                    tokenB
                );
        }

        (
            uint reserveA,
            uint reserveB
        ) =
            ApexV2Library.getReserves(
                factory,
                tokenA,
                tokenB
            );

        if (
            reserveA == 0 &&
            reserveB == 0
        ) {
            amountA = amountADesired;
            amountB = amountBDesired;
        }
        else {
            uint amountBOptimal =
                ApexV2Library.quote(
                    amountADesired,
                    reserveA,
                    reserveB
                );

            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "ApexV2Router: B_LOW"
                );

                amountA = amountADesired;
                amountB = amountBOptimal;
            }
            else {
                uint amountAOptimal =
                    ApexV2Library.quote(
                        amountBDesired,
                        reserveB,
                        reserveA
                    );

                require(
                    amountAOptimal <= amountADesired,
                    "ApexV2Router: A_HIGH"
                );

                require(
                    amountAOptimal >= amountAMin,
                    "ApexV2Router: A_LOW"
                );

                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        _transferFrom(
            tokenA,
            msg.sender,
            pair,
            amountA
        );

        _transferFrom(
            tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity =
            IApexV2Pair(pair).mint(to);
    }

    // ============================================================
    // ADD LIQUIDITY ETH
    // ============================================================

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        )
    {
        require(
            token != WETH,
            "ApexV2Router: INVALID_TOKEN"
        );

        amountToken = amountTokenDesired;
        amountETH = msg.value;

        require(
            amountToken >= amountTokenMin,
            "ApexV2Router: TOKEN_LOW"
        );

        require(
            amountETH >= amountETHMin,
            "ApexV2Router: ETH_LOW"
        );

        address pair =
            IApexV2Factory(factory).getPair(
                token,
                WETH
            );

        if (pair == address(0)) {
            pair =
                IApexV2Factory(factory).createPair(
                    token,
                    WETH
                );
        }

        _transferFrom(
            token,
            msg.sender,
            pair,
            amountToken
        );

        IWETH9(WETH).deposit{
            value: amountETH
        }();

        _safeTransfer(
            WETH,
            pair,
            amountETH
        );

        liquidity =
            IApexV2Pair(pair).mint(to);
    }

    // ============================================================
    // REMOVE LIQUIDITY
    // ============================================================

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        public
        ensure(deadline)
        returns (
            uint amountA,
            uint amountB
        )
    {
        address pair =
            ApexV2Library.pairFor(
                factory,
                tokenA,
                tokenB
            );

        require(
            pair != address(0),
            "ApexV2Router: PAIR_NOT_FOUND"
        );

        IERC20(pair).transferFrom(
            msg.sender,
            pair,
            liquidity
        );

        (
            uint amount0,
            uint amount1
        ) =
            IApexV2Pair(pair).burn(to);

        address token0 =
            tokenA < tokenB
                ? tokenA
                : tokenB;

        if (tokenA == token0) {
            amountA = amount0;
            amountB = amount1;
        }
        else {
            amountA = amount1;
            amountB = amount0;
        }

        require(
            amountA >= amountAMin,
            "ApexV2Router: A_LOW"
        );

        require(
            amountB >= amountBMin,
            "ApexV2Router: B_LOW"
        );
    }

    // ============================================================
    // REMOVE LIQUIDITY ETH
    // ============================================================

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountToken,
            uint amountETH
        )
    {
        (
            amountToken,
            amountETH
        ) =
            removeLiquidity(
                token,
                WETH,
                liquidity,
                amountTokenMin,
                amountETHMin,
                address(this),
                deadline
            );

        _safeTransfer(
            token,
            to,
            amountToken
        );

        IWETH9(WETH).withdraw(
            amountETH
        );

        (bool success,) =
            payable(to).call{
                value: amountETH
            }("");

        require(
            success,
            "ApexV2Router: ETH_TRANSFER_FAILED"
        );
    }

    // ============================================================
    // SWAP EXACT TOKENS FOR TOKENS
    // ============================================================

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        ensure(deadline)
        returns (
            uint[] memory amounts
        )
    {
        require(
            path.length >= 2,
            "ApexV2Router: INVALID_PATH"
        );

        amounts =
            ApexV2Library.getAmountsOut(
                factory,
                amountIn,
                path
            );

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "ApexV2Router: SLIPPAGE"
        );

        address firstPair =
            ApexV2Library.pairFor(
                factory,
                path[0],
                path[1]
            );

        require(
            firstPair != address(0),
            "ApexV2Router: PAIR_NOT_FOUND"
        );

        _transferFrom(
            path[0],
            msg.sender,
            firstPair,
            amountIn
        );

        _swap(
            amounts,
            path,
            to
        );
    }

    // ============================================================
    // SWAP EXACT ETH FOR TOKENS
    // ============================================================

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint[] memory amounts
        )
    {
        require(
            path.length >= 2,
            "ApexV2Router: INVALID_PATH"
        );

        require(
            path[0] == WETH,
            "ApexV2Router: INVALID_WETH_PATH"
        );

        amounts =
            ApexV2Library.getAmountsOut(
                factory,
                msg.value,
                path
            );

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "ApexV2Router: SLIPPAGE"
        );

        address pair =
            ApexV2Library.pairFor(
                factory,
                path[0],
                path[1]
            );

        require(
            pair != address(0),
            "ApexV2Router: PAIR_NOT_FOUND"
        );

        IWETH9(WETH).deposit{
            value: msg.value
        }();

        _safeTransfer(
            WETH,
            pair,
            msg.value
        );

        _swap(
            amounts,
            path,
            to
        );
    }

    // ============================================================
    // SWAP EXACT TOKENS FOR ETH
    // ============================================================

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        ensure(deadline)
        returns (
            uint[] memory amounts
        )
    {
        require(
            path.length >= 2,
            "ApexV2Router: INVALID_PATH"
        );

        require(
            path[path.length - 1] == WETH,
            "ApexV2Router: INVALID_WETH_PATH"
        );

        amounts =
            ApexV2Library.getAmountsOut(
                factory,
                amountIn,
                path
            );

        uint amountWETH =
            amounts[amounts.length - 1];

        require(
            amountWETH >= amountOutMin,
            "ApexV2Router: SLIPPAGE"
        );

        address firstPair =
            ApexV2Library.pairFor(
                factory,
                path[0],
                path[1]
            );

        require(
            firstPair != address(0),
            "ApexV2Router: PAIR_NOT_FOUND"
        );

        _transferFrom(
            path[0],
            msg.sender,
            firstPair,
            amountIn
        );

        _swap(
            amounts,
            path,
            address(this)
        );

        /*
         * CRITICAL:
         *
         * Do NOT use the router's entire WETH balance here.
         *
         * Only unwrap the WETH amount generated by this swap.
         */
        IWETH9(WETH).withdraw(
            amountWETH
        );

        (bool success,) =
            payable(to).call{
                value: amountWETH
            }("");

        require(
            success,
            "ApexV2Router: ETH_FAILED"
        );
    }

    // ============================================================
    // INTERNAL SWAP
    // ============================================================

    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address to
    )
        internal
    {
        require(
            path.length >= 2,
            "ApexV2Router: INVALID_PATH"
        );

        require(
            amounts.length == path.length,
            "ApexV2Router: INVALID_AMOUNTS"
        );

        for (
            uint i = 0;
            i < path.length - 1;
            i++
        ) {
            address input =
                path[i];

            address output =
                path[i + 1];

            address pair =
                ApexV2Library.pairFor(
                    factory,
                    input,
                    output
                );

            require(
                pair != address(0),
                "ApexV2Router: PAIR_NOT_FOUND"
            );

            address token0 =
                input < output
                    ? input
                    : output;

            uint amountOut =
                amounts[i + 1];

            uint amount0Out;
            uint amount1Out;

            if (input == token0) {
                amount0Out = 0;
                amount1Out = amountOut;
            }
            else {
                amount0Out = amountOut;
                amount1Out = 0;
            }

            address receiver;

            if (i < path.length - 2) {
                receiver =
                    ApexV2Library.pairFor(
                        factory,
                        output,
                        path[i + 2]
                    );

                require(
                    receiver != address(0),
                    "ApexV2Router: NEXT_PAIR_MISSING"
                );
            }
            else {
                receiver = to;
            }

            IApexV2Pair(pair).swap(
                amount0Out,
                amount1Out,
                receiver,
                new bytes(0)
            );
        }
    }

    // ============================================================
    // INTERNAL TRANSFER FROM
    // ============================================================

    function _transferFrom(
        address token,
        address from,
        address to,
        uint value
    )
        internal
    {
        (
            bool success,
            bytes memory data
        ) =
            token.call(
                abi.encodeWithSelector(
                    IERC20.transferFrom.selector,
                    from,
                    to,
                    value
                )
            );

        require(
            success,
            "ApexV2Router: TRANSFER_FROM_FAILED"
        );

        require(
            data.length == 32,
            "ApexV2Router: NO_RETURN_DATA"
        );

        require(
            abi.decode(
                data,
                (bool)
            ),
            "ApexV2Router: TRANSFER_FROM_FALSE"
        );
    }

    // ============================================================
    // INTERNAL SAFE TRANSFER
    // ============================================================

    function _safeTransfer(
        address token,
        address to,
        uint value
    )
        internal
    {
        (
            bool success,
            bytes memory data
        ) =
            token.call(
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    to,
                    value
                )
            );

        require(
            success &&
            (
                data.length == 0 ||
                (
                    data.length == 32 &&
                    abi.decode(
                        data,
                        (bool)
                    )
                )
            ),
            "ApexV2Router: TRANSFER_FAILED"
        );
    }
}