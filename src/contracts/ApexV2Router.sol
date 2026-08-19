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

    modifier ensure(uint256 deadline) {
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

    // ============================================================
    // RECEIVE
    // ============================================================

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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
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

        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

        require(
            amountADesired > 0,
            "ApexV2Router: A_ZERO"
        );

        require(
            amountBDesired > 0,
            "ApexV2Router: B_ZERO"
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
            uint256 reserveA,
            uint256 reserveB
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

            require(
                amountA >= amountAMin,
                "ApexV2Router: A_LOW"
            );

            require(
                amountB >= amountBMin,
                "ApexV2Router: B_LOW"
            );
        }
        else {
            require(
                reserveA > 0 &&
                reserveB > 0,
                "ApexV2Router: INVALID_RESERVES"
            );

            uint256 amountBOptimal =
                ApexV2Library.quote(
                    amountADesired,
                    reserveA,
                    reserveB
                );

            if (
                amountBOptimal <= amountBDesired
            ) {
                require(
                    amountADesired >= amountAMin,
                    "ApexV2Router: A_LOW"
                );

                require(
                    amountBOptimal >= amountBMin,
                    "ApexV2Router: B_LOW"
                );

                amountA = amountADesired;
                amountB = amountBOptimal;
            }
            else {
                uint256 amountAOptimal =
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

                require(
                    amountBDesired >= amountBMin,
                    "ApexV2Router: B_LOW"
                );

                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        require(
            amountA > 0,
            "ApexV2Router: A_ZERO"
        );

        require(
            amountB > 0,
            "ApexV2Router: B_ZERO"
        );

        _safeTransferFrom(
            tokenA,
            msg.sender,
            pair,
            amountA
        );

        _safeTransferFrom(
            tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity =
            IApexV2Pair(pair).mint(to);

        require(
            liquidity > 0,
            "ApexV2Router: INSUFFICIENT_LIQUIDITY_MINTED"
        );
    }

    // ============================================================
    // ADD LIQUIDITY ETH
    // ============================================================

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        require(
            token != address(0),
            "ApexV2Router: ZERO_ADDRESS"
        );

        require(
            token != WETH,
            "ApexV2Router: INVALID_TOKEN"
        );

        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

        require(
            amountTokenDesired > 0,
            "ApexV2Router: TOKEN_ZERO"
        );

        require(
            msg.value > 0,
            "ApexV2Router: ETH_ZERO"
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

        (
            uint256 reserveToken,
            uint256 reserveETH
        ) =
            ApexV2Library.getReserves(
                factory,
                token,
                WETH
            );

        if (
            reserveToken == 0 &&
            reserveETH == 0
        ) {
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
        }
        else {
            require(
                reserveToken > 0 &&
                reserveETH > 0,
                "ApexV2Router: INVALID_RESERVES"
            );

            uint256 amountETHOptimal =
                ApexV2Library.quote(
                    amountTokenDesired,
                    reserveToken,
                    reserveETH
                );

            if (
                amountETHOptimal <= msg.value
            ) {
                require(
                    amountTokenDesired >= amountTokenMin,
                    "ApexV2Router: TOKEN_LOW"
                );

                require(
                    amountETHOptimal >= amountETHMin,
                    "ApexV2Router: ETH_LOW"
                );

                amountToken = amountTokenDesired;
                amountETH = amountETHOptimal;
            }
            else {
                uint256 amountTokenOptimal =
                    ApexV2Library.quote(
                        msg.value,
                        reserveETH,
                        reserveToken
                    );

                require(
                    amountTokenOptimal <= amountTokenDesired,
                    "ApexV2Router: TOKEN_HIGH"
                );

                require(
                    amountTokenOptimal >= amountTokenMin,
                    "ApexV2Router: TOKEN_LOW"
                );

                require(
                    msg.value >= amountETHMin,
                    "ApexV2Router: ETH_LOW"
                );

                amountToken = amountTokenOptimal;
                amountETH = msg.value;
            }
        }

        require(
            amountToken > 0,
            "ApexV2Router: TOKEN_ZERO"
        );

        require(
            amountETH > 0,
            "ApexV2Router: ETH_ZERO"
        );

        _safeTransferFrom(
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

        require(
            liquidity > 0,
            "ApexV2Router: INSUFFICIENT_LIQUIDITY_MINTED"
        );

        uint256 refundETH =
            msg.value - amountETH;

        if (refundETH > 0) {
            _safeTransferETH(
                msg.sender,
                refundETH
            );
        }
    }

    // ============================================================
    // REMOVE LIQUIDITY
    // ============================================================

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB
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

        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

        require(
            liquidity > 0,
            "ApexV2Router: LIQUIDITY_ZERO"
        );

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

        _safeTransferFrom(
            pair,
            msg.sender,
            pair,
            liquidity
        );

        (
            uint256 amount0,
            uint256 amount1
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
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH
        )
    {
        require(
            token != address(0),
            "ApexV2Router: ZERO_ADDRESS"
        );

        require(
            token != WETH,
            "ApexV2Router: INVALID_TOKEN"
        );

        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

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

        _safeTransferETH(
            to,
            amountETH
        );
    }

    // ============================================================
    // SWAP EXACT TOKENS FOR TOKENS
    // ============================================================

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256[] memory amounts
        )
    {
        require(
            amountIn > 0,
            "ApexV2Router: INSUFFICIENT_INPUT"
        );

        _validateSwapPath(
            path,
            to
        );

        amounts =
            ApexV2Library.getAmountsOut(
                factory,
                amountIn,
                path
            );

        uint256 amountOut =
            amounts[amounts.length - 1];

        require(
            amountOut >= amountOutMin,
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

        _safeTransferFrom(
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
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint256[] memory amounts
        )
    {
        require(
            msg.value > 0,
            "ApexV2Router: INSUFFICIENT_INPUT"
        );

        require(
            path.length >= 2,
            "ApexV2Router: INVALID_PATH"
        );

        require(
            path[0] == WETH,
            "ApexV2Router: INVALID_WETH_PATH"
        );

        _validateSwapPath(
            path,
            to
        );

        amounts =
            ApexV2Library.getAmountsOut(
                factory,
                msg.value,
                path
            );

        uint256 amountOut =
            amounts[amounts.length - 1];

        require(
            amountOut >= amountOutMin,
            "ApexV2Router: SLIPPAGE"
        );

        IWETH9(WETH).deposit{
            value: msg.value
        }();

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
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256[] memory amounts
        )
    {
        require(
            amountIn > 0,
            "ApexV2Router: INSUFFICIENT_INPUT"
        );

        require(
            path.length >= 2,
            "ApexV2Router: INVALID_PATH"
        );

        require(
            path[path.length - 1] == WETH,
            "ApexV2Router: INVALID_WETH_PATH"
        );

        _validateSwapPath(
            path,
            to
        );

        amounts =
            ApexV2Library.getAmountsOut(
                factory,
                amountIn,
                path
            );

        uint256 amountWETH =
            amounts[amounts.length - 1];

        require(
            amountWETH >= amountOutMin,
            "ApexV2Router: SLIPPAGE"
        );

        require(
            amountWETH > 0,
            "ApexV2Router: ZERO_OUTPUT"
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

        _safeTransferFrom(
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

        IWETH9(WETH).withdraw(
            amountWETH
        );

        _safeTransferETH(
            to,
            amountWETH
        );
    }

    // ============================================================
    // INTERNAL SWAP
    // ============================================================

    function _swap(
        uint256[] memory amounts,
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

        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

        for (
            uint256 i = 0;
            i < path.length - 1;
            ++i
        ) {
            address input =
                path[i];

            address output =
                path[i + 1];

            require(
                input != address(0) &&
                output != address(0),
                "ApexV2Router: ZERO_ADDRESS"
            );

            require(
                input != output,
                "ApexV2Router: IDENTICAL_TOKEN"
            );

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

            uint256 amountOut =
                amounts[i + 1];

            require(
                amountOut > 0,
                "ApexV2Router: ZERO_OUTPUT"
            );

            address token0 =
                input < output
                    ? input
                    : output;

            uint256 amount0Out;
            uint256 amount1Out;

            if (input == token0) {
                amount0Out = 0;
                amount1Out = amountOut;
            }
            else {
                amount0Out = amountOut;
                amount1Out = 0;
            }

            address receiver;

            if (
                i < path.length - 2
            ) {
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
    // INTERNAL SWAP PATH VALIDATION
    // ============================================================

    function _validateSwapPath(
        address[] calldata path,
        address to
    )
        internal
        view
    {
        require(
            path.length >= 2,
            "ApexV2Router: INVALID_PATH"
        );

        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

        for (
            uint256 i = 0;
            i < path.length;
            ++i
        ) {
            address token =
                path[i];

            require(
                token != address(0),
                "ApexV2Router: ZERO_ADDRESS"
            );

            if (i > 0) {
                require(
                    token != path[i - 1],
                    "ApexV2Router: IDENTICAL_TOKEN"
                );

                address pair =
                    ApexV2Library.pairFor(
                        factory,
                        path[i - 1],
                        token
                    );

                require(
                    pair != address(0),
                    "ApexV2Router: PAIR_NOT_FOUND"
                );
            }
        }
    }

    // ============================================================
    // INTERNAL SAFE TRANSFER FROM
    // ============================================================

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        require(
            token != address(0),
            "ApexV2Router: ZERO_TOKEN"
        );

        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

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
            data.length == 0 ||
            (
                data.length == 32 &&
                abi.decode(
                    data,
                    (bool)
                )
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
        uint256 value
    )
        internal
    {
        require(
            token != address(0),
            "ApexV2Router: ZERO_TOKEN"
        );

        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

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

    // ============================================================
    // INTERNAL SAFE ETH TRANSFER
    // ============================================================

    function _safeTransferETH(
        address to,
        uint256 value
    )
        internal
    {
        require(
            to != address(0),
            "ApexV2Router: ZERO_RECIPIENT"
        );

        (bool success,) =
            payable(to).call{
                value: value
            }("");

        require(
            success,
            "ApexV2Router: ETH_TRANSFER_FAILED"
        );
    }
}