// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/interfaces/IApexV2Factory.sol";
import "../src/contracts/interfaces/IApexV2Pair.sol";
import "../src/contracts/interfaces/IERC20.sol";
import "../src/contracts/interfaces/IWETH9.sol";
import "../src/contracts/libraries/ApexV2Library.sol";

// ============================================================================
// MOCK TOKEN
// ============================================================================

contract MockRouterToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "MockToken";
    string public symbol = "MOCK";
    uint8 public decimals = 18;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        require(
            balanceOf[msg.sender] >= amount,
            "MockToken: BALANCE"
        );

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        require(
            balanceOf[from] >= amount,
            "MockToken: BALANCE"
        );

        uint256 currentAllowance =
            allowance[from][msg.sender];

        require(
            currentAllowance >= amount,
            "MockToken: ALLOWANCE"
        );

        allowance[from][msg.sender] =
            currentAllowance - amount;

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        return true;
    }
}

// ============================================================================
// MOCK PAIR
// ============================================================================

contract MockRouterPair {
    address public token0;
    address public token1;

    address public lastMintRecipient;

    uint112 private reserve0;
    uint112 private reserve1;

    bool public revertOnMint;

    constructor(
        address _token0,
        address _token1
    )
    {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (
            reserve0,
            reserve1,
            0
        );
    }

    function setReserves(
        uint112 _reserve0,
        uint112 _reserve1
    )
        external
    {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function setRevertOnMint(
        bool value
    )
        external
    {
        revertOnMint = value;
    }

    function mint(
        address to
    )
        external
        returns (
            uint amount0,
            uint amount1,
            uint liquidity
        )
    {
        if (revertOnMint) {
            revert(
                "ApexV2Router: DUMMY"
            );
        }

        lastMintRecipient = to;

        return (
            100,
            100,
            1
        );
    }

    function swap(
        uint,
        uint,
        address,
        bytes calldata
    )
        external
    {
        revert(
            "MockRouterPair: SWAP_NOT_IMPLEMENTED"
        );
    }

    function burn(
        address
    )
        external
        returns (
            uint,
            uint
        )
    {
        revert(
            "MockRouterPair: BURN_NOT_IMPLEMENTED"
        );
    }
}

// ============================================================================
// MOCK FACTORY
// ============================================================================

contract MockRouterFactory {
    mapping(bytes32 => address) public pairs;

    address public lastCreatedPair;

    function _pairKey(
        address tokenA,
        address tokenB
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                tokenA < tokenB
                    ? tokenA
                    : tokenB,
                tokenA < tokenB
                    ? tokenB
                    : tokenA
            )
        );
    }

    function getPair(
        address tokenA,
        address tokenB
    )
        external
        view
        returns (address)
    {
        return pairs[
            _pairKey(
                tokenA,
                tokenB
            )
        ];
    }

    function createPair(
        address tokenA,
        address tokenB
    )
        external
        returns (address pair)
    {
        bytes32 key =
            _pairKey(
                tokenA,
                tokenB
            );

        require(
            pairs[key] == address(0),
            "MockFactory: EXISTS"
        );

        pair =
            address(
                new MockRouterPair(
                    tokenA < tokenB
                        ? tokenA
                        : tokenB,
                    tokenA < tokenB
                        ? tokenB
                        : tokenA
                )
            );

        pairs[key] = pair;
        lastCreatedPair = pair;
    }
}

// ============================================================================
// MOCK WETH
// ============================================================================

contract MockRouterWETH {
    mapping(address => uint256) public balanceOf;

    function deposit()
        external
        payable
    {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw(
        uint256 amount
    )
        external
    {
        require(
            balanceOf[msg.sender] >= amount,
            "MockWETH: BALANCE"
        );

        balanceOf[msg.sender] -= amount;

        (bool success,) =
            payable(msg.sender).call{
                value: amount
            }("");

        require(success);
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        require(
            balanceOf[msg.sender] >= amount,
            "MockWETH: BALANCE"
        );

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        return true;
    }

    receive()
        external
        payable
    {}
}

// ============================================================================
// ROUTER
// ============================================================================

contract ApexV2Router {
    address public immutable factory;
    address public immutable WETH;

    modifier ensure(uint deadline)
    {
        require(
            deadline >= block.timestamp,
            "ApexV2Router: EXPIRED"
        );
        _;
    }

    constructor(
        address _factory,
        address _WETH
    )
    {
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

    receive()
        external
        payable
    {
        require(
            msg.sender == WETH,
            "ApexV2Router: ONLY_WETH"
        );
    }

    // ========================================================================
    // ADD LIQUIDITY
    // ========================================================================

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

    // ========================================================================
    // ADD LIQUIDITY ETH
    // ========================================================================

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

    // ========================================================================
    // REMOVE LIQUIDITY
    // ========================================================================

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
            IApexV2Pair(pair).burn(
                to
            );

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

    // ========================================================================
    // REMOVE LIQUIDITY ETH
    // ========================================================================

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

    // ========================================================================
    // SWAP TOKENS -> TOKENS
    // ========================================================================

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
            amounts[amounts.length - 1]
                >= amountOutMin,
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

    // ========================================================================
    // SWAP ETH -> TOKENS
    // ========================================================================

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
            amounts[amounts.length - 1]
                >= amountOutMin,
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

    // ========================================================================
    // SWAP TOKENS -> ETH
    // ========================================================================

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

    // ========================================================================
    // INTERNAL SWAP
    // ========================================================================

    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address to
    )
        internal
    {
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

    // ========================================================================
    // TRANSFER FROM
    // ========================================================================

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

    // ========================================================================
    // SAFE TRANSFER
    // ========================================================================

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
        )
        =
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
                abi.decode(
                    data,
                    (bool)
                )
            ),
            "ApexV2Router: TRANSFER_FAILED"
        );
    }
}

// ============================================================================
// SECURITY TEST
// ============================================================================

contract ApexV2RouterSecurityTest
    is Test
{
    ApexV2Router public router;

    MockRouterFactory public factory;
    MockRouterWETH public weth;

    MockRouterToken public tokenA;
    MockRouterToken public tokenB;

    address public pair;

    address constant USER =
        address(0xA11CE);

    address constant USER2 =
        address(0xB0B);

    address constant TOKEN =
        address(0x3000);

    // ========================================================================
    // SETUP
    // ========================================================================

    function setUp()
        public
    {
        factory =
            new MockRouterFactory();

        weth =
            new MockRouterWETH();

        tokenA =
            new MockRouterToken();

        tokenB =
            new MockRouterToken();

        router =
            new ApexV2Router(
                address(factory),
                address(weth)
            );

        vm.deal(
            USER,
            100 ether
        );

        vm.deal(
            USER2,
            100 ether
        );

        tokenA.mint(
            USER,
            1_000_000
        );

        tokenB.mint(
            USER,
            1_000_000
        );

        tokenA.mint(
            USER2,
            1_000_000
        );

        tokenB.mint(
            USER2,
            1_000_000
        );

        vm.prank(USER);

        tokenA.approve(
            address(router),
            type(uint).max
        );

        vm.prank(USER);

        tokenB.approve(
            address(router),
            type(uint).max
        );

        vm.prank(USER2);

        tokenA.approve(
            address(router),
            type(uint).max
        );

        vm.prank(USER2);

        tokenB.approve(
            address(router),
            type(uint).max
        );
    }

    // ========================================================================
    // CONSTRUCTOR
    // ========================================================================

    function testConstructorRejectsZeroFactory()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_FACTORY"
            )
        );

        new ApexV2Router(
            address(0),
            address(weth)
        );
    }

    function testConstructorRejectsZeroWETH()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_WETH"
            )
        );

        new ApexV2Router(
            address(factory),
            address(0)
        );
    }

    function testConstructorStoresFactory()
        public
    {
        assertEq(
            router.factory(),
            address(factory)
        );
    }

    function testConstructorStoresWETH()
        public
    {
        assertEq(
            router.WETH(),
            address(weth)
        );
    }

    // ========================================================================
    // ADD LIQUIDITY
    // ========================================================================

    function testAddLiquidityRejectsExpiredDeadline()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.addLiquidity(
            address(0x10),
            address(0x20),
            100,
            100,
            0,
            0,
            USER,
            0
        );
    }

    function testAddLiquidityRejectsIdenticalTokens()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: IDENTICAL_TOKEN"
            )
        );

        router.addLiquidity(
            address(0x1234),
            address(0x1234),
            100,
            100,
            0,
            0,
            USER,
            block.timestamp
        );
    }

    function testAddLiquidityRejectsZeroTokenA()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_ADDRESS"
            )
        );

        router.addLiquidity(
            address(0),
            address(0x20),
            100,
            100,
            0,
            0,
            USER,
            block.timestamp
        );
    }

    function testAddLiquidityRejectsZeroTokenB()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ZERO_ADDRESS"
            )
        );

        router.addLiquidity(
            address(0x10),
            address(0),
            100,
            100,
            0,
            0,
            USER,
            block.timestamp
        );
    }

    // ========================================================================
    // ZERO RECIPIENT
    // ========================================================================

    function testAddLiquidityAllowsZeroRecipientUntilPairMint()
    public
{
    // ------------------------------------------------------------
    // Arrange
    // ------------------------------------------------------------

    // Give the test contract enough tokens because msg.sender
    // inside router.addLiquidity() is this test contract.
    tokenA.mint(
        address(this),
        100
    );

    tokenB.mint(
        address(this),
        100
    );

    // Approve router to spend tokens from this test contract.
    tokenA.approve(
        address(router),
        type(uint).max
    );

    tokenB.approve(
        address(router),
        type(uint).max
    );

    // Create the pair first so we can configure the mock pair.
    router.addLiquidity(
        address(tokenA),
        address(tokenB),
        0,
        0,
        0,
        0,
        address(this),
        block.timestamp
    );

    pair = factory.lastCreatedPair();

    // Configure the pair to revert during mint().
    MockRouterPair(pair).setRevertOnMint(true);

    // ------------------------------------------------------------
    // Act + Assert
    // ------------------------------------------------------------

    vm.expectRevert(
        bytes(
            "ApexV2Router: DUMMY"
        )
    );

    router.addLiquidity(
        address(tokenA),
        address(tokenB),
        100,
        100,
        0,
        0,
        address(0),
        block.timestamp
    );
}

    // ========================================================================
    // DEADLINE
    // ========================================================================

    function testDeadlineExactlyAtTimestampIsAccepted()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: IDENTICAL_TOKEN"
            )
        );

        router.addLiquidity(
            address(0x1234),
            address(0x1234),
            100,
            100,
            0,
            0,
            USER,
            block.timestamp
        );
    }

    // ========================================================================
    // ADD LIQUIDITY ETH
    // ========================================================================

    function testAddLiquidityETHRejectsExpiredDeadline()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(0x10),
            100,
            0,
            0,
            USER,
            0
        );
    }

    function testAddLiquidityETHRejectsWETHAsToken()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_TOKEN"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            address(weth),
            100,
            0,
            0,
            USER,
            block.timestamp
        );
    }

    function testAddLiquidityETHRejectsETHBelowMinimum()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ETH_LOW"
            )
        );

        router.addLiquidityETH{
            value: 0.5 ether
        }(
            TOKEN,
            100,
            0,
            1 ether,
            USER,
            block.timestamp
        );
    }

    function testAddLiquidityETHRejectsTokenBelowMinimum()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: TOKEN_LOW"
            )
        );

        router.addLiquidityETH{
            value: 1 ether
        }(
            TOKEN,
            99,
            100,
            0,
            USER,
            block.timestamp
        );
    }

    // ========================================================================
    // RECEIVE
    // ========================================================================

    function testReceiveRejectsETHFromNonWETH()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ONLY_WETH"
            )
        );

        address(router).call{
            value: 1 ether
        }("");
    }

    function testRouterDoesNotAcceptArbitraryETH()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: ONLY_WETH"
            )
        );

        address(router).call{
            value: 0.5 ether
        }("");
    }

    // ========================================================================
    // REMOVE LIQUIDITY
    // ========================================================================

    function testRemoveLiquidityRejectsExpiredDeadline()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.removeLiquidity(
            address(0x10),
            address(weth),
            100,
            0,
            0,
            USER,
            0
        );
    }

    function testRemoveLiquidityETHRejectsExpiredDeadline()
        public
    {
        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.removeLiquidityETH(
            address(0x10),
            100,
            0,
            0,
            USER,
            0
        );
    }

    // ========================================================================
    // TOKENS -> TOKENS
    // ========================================================================

    function testSwapTokensForTokensRejectsExpiredDeadline()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(0x10);
        path[1] = address(0x20);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.swapExactTokensForTokens(
            100,
            0,
            path,
            USER,
            0
        );
    }

    function testSwapTokensForTokensRejectsEmptyPath()
        public
    {
        address[] memory path =
            new address[](0);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForTokens(
            100,
            0,
            path,
            USER,
            block.timestamp
        );
    }

    function testSwapTokensForTokensRejectsOneTokenPath()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(0x10);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForTokens(
            100,
            0,
            path,
            USER,
            block.timestamp
        );
    }

    function testSwapTokensForTokensZeroAmountDoesNotBypassPathCheck()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(0x10);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForTokens(
            0,
            0,
            path,
            USER,
            block.timestamp
        );
    }

    // ========================================================================
    // ETH -> TOKENS
    // ========================================================================

    function testSwapETHForTokensRejectsExpiredDeadline()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(weth);
        path[1] = address(0x20);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.swapExactETHForTokens{
            value: 1 ether
        }(
            0,
            path,
            USER,
            0
        );
    }

    function testSwapETHForTokensRejectsEmptyPath()
        public
    {
        address[] memory path =
            new address[](0);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactETHForTokens{
            value: 1 ether
        }(
            0,
            path,
            USER,
            block.timestamp
        );
    }

    function testSwapETHForTokensRejectsOneTokenPath()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(weth);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactETHForTokens{
            value: 1 ether
        }(
            0,
            path,
            USER,
            block.timestamp
        );
    }

    function testSwapETHForTokensRejectsWrongFirstToken()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(0x1234);
        path[1] = address(0x5678);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_WETH_PATH"
            )
        );

        router.swapExactETHForTokens{
            value: 1 ether
        }(
            0,
            path,
            USER,
            block.timestamp
        );
    }

    function testSwapETHForTokensZeroValueDoesNotBypassPathCheck()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(weth);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactETHForTokens(
            0,
            path,
            USER,
            block.timestamp
        );
    }

    // ========================================================================
    // TOKENS -> ETH
    // ========================================================================

    function testSwapTokensForETHRejectsExpiredDeadline()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(0x10);
        path[1] = address(weth);

        vm.expectRevert(
            bytes(
                "ApexV2Router: EXPIRED"
            )
        );

        router.swapExactTokensForETH(
            100,
            0,
            path,
            USER,
            0
        );
    }

    function testSwapTokensForETHRejectsEmptyPath()
        public
    {
        address[] memory path =
            new address[](0);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForETH(
            100,
            0,
            path,
            USER,
            block.timestamp
        );
    }

    function testSwapTokensForETHRejectsOneTokenPath()
        public
    {
        address[] memory path =
            new address[](1);

        path[0] = address(0x10);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_PATH"
            )
        );

        router.swapExactTokensForETH(
            100,
            0,
            path,
            USER,
            block.timestamp
        );
    }

    function testSwapTokensForETHRejectsWrongLastToken()
        public
    {
        address[] memory path =
            new address[](2);

        path[0] = address(0x1234);
        path[1] = address(0x5678);

        vm.expectRevert(
            bytes(
                "ApexV2Router: INVALID_WETH_PATH"
            )
        );

        router.swapExactTokensForETH(
            100,
            0,
            path,
            USER,
            block.timestamp
        );
    }
}