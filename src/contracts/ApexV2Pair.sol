// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./ApexV2ERC20.sol";
import "./interfaces/IApexV2Pair.sol";
import "./interfaces/IApexV2Factory.sol";
import "./interfaces/IApexV2Callee.sol";
import "./interfaces/IERC20.sol";
import "./libraries/ApexMath.sol";
import "./libraries/UQ112x112.sol";

contract ApexV2Pair is IApexV2Pair, ApexV2ERC20 {
    using UQ112x112 for uint224;

    // ============================================================
    // ERRORS
    // ============================================================

    error Forbidden();
    error AlreadyInitialized();
    error Locked();
    error Overflow();
    error TransferFailed();

    error InvalidTokenAddress();
    error IdenticalTokens();

    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();

    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error InvalidTo();
    error InsufficientInputAmount();
    error K();

    // ============================================================
    // CONSTANTS
    // ============================================================

    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));

    // ============================================================
    // IMMUTABLE / TOKENS
    // ============================================================

    address public immutable factory;

    address public token0;
    address public token1;

    // ============================================================
    // RESERVES / ORACLE
    // ============================================================

    uint112 private reserve0;
    uint112 private reserve1;

    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    // ============================================================
    // PROTOCOL FEE
    // ============================================================

    uint256 public kLast;

    // ============================================================
    // INITIALIZATION / REENTRANCY
    // ============================================================

    bool private initialized;
    uint256 private unlocked = 1;

    modifier lock() {
        if (unlocked != 1) {
            revert Locked();
        }

        unlocked = 0;
        _;
        unlocked = 1;
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() {
        factory = msg.sender;
    }

    // ============================================================
    // INITIALIZE
    // ============================================================

    function initialize(address _token0, address _token1) external {
        if (msg.sender != factory) {
            revert Forbidden();
        }

        if (initialized) {
            revert AlreadyInitialized();
        }

        if (_token0 == address(0) || _token1 == address(0)) {
            revert InvalidTokenAddress();
        }

        if (_token0 == _token1) {
            revert IdenticalTokens();
        }

        token0 = _token0;
        token1 = _token1;

        initialized = true;
    }

    // ============================================================
    // RESERVES
    // ============================================================

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // ============================================================
    // SAFE TRANSFER
    // ============================================================

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));

        if (!success) {
            revert TransferFailed();
        }

        // Non-standard ERC20s that return no data are accepted.
        if (data.length == 0) {
            return;
        }

        // A valid ERC20 boolean return must occupy one ABI word.
        if (data.length != 32) {
            revert TransferFailed();
        }

        if (!abi.decode(data, (bool))) {
            revert TransferFailed();
        }
    }

    // ============================================================
    // UPDATE RESERVES / ORACLE
    // ============================================================

    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) {
            revert Overflow();
        }

        uint32 timestamp = uint32(block.timestamp);

        uint32 timeElapsed;

        // uint32 timestamp rollover is intentional.
        unchecked {
            timeElapsed = timestamp - blockTimestampLast;
        }

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            /*
             * Cumulative-price overflow is intentional.
             *
             * Oracle consumers use differences between cumulative
             * observations, so modulo-2^256 arithmetic is expected.
             */
            unchecked {
                price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * uint256(timeElapsed);

                price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * uint256(timeElapsed);
            }
        }

        reserve0 = uint112(balance0);

        reserve1 = uint112(balance1);

        blockTimestampLast = timestamp;

        emit Sync(reserve0, reserve1);
    }

    // ============================================================
    // PROTOCOL FEE
    // ============================================================

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IApexV2Factory(factory).feeTo();

        feeOn = feeTo != address(0);

        uint256 _kLast = kLast;

        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = ApexMath.sqrt(uint256(_reserve0) * uint256(_reserve1));

                uint256 rootKLast = ApexMath.sqrt(_kLast);

                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);

                    uint256 denominator = rootK * 5 + rootKLast;

                    uint256 liquidity = numerator / denominator;

                    if (liquidity > 0) {
                        _mint(feeTo, liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // ============================================================
    // MINT
    // ============================================================

    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));

        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - uint256(_reserve0);

        uint256 amount1 = balance1 - uint256(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);

        uint256 _totalSupply = totalSupply;

        if (_totalSupply == 0) {
            uint256 root = ApexMath.sqrt(amount0 * amount1);

            if (root <= MINIMUM_LIQUIDITY) {
                revert InsufficientLiquidityMinted();
            }

            liquidity = root - MINIMUM_LIQUIDITY;

            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = ApexMath.min(
                (amount0 * _totalSupply) / uint256(_reserve0), (amount1 * _totalSupply) / uint256(_reserve1)
            );
        }

        if (liquidity == 0) {
            revert InsufficientLiquidityMinted();
        }

        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);

        if (feeOn) {
            kLast = uint256(reserve0) * uint256(reserve1);
        }

        emit Mint(msg.sender, amount0, amount1);
    }

    // ============================================================
    // BURN
    // ============================================================

    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));

        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);

        uint256 _totalSupply = totalSupply;

        amount0 = (liquidity * balance0) / _totalSupply;

        amount1 = (liquidity * balance1) / _totalSupply;

        if (amount0 == 0 || amount1 == 0) {
            revert InsufficientLiquidityBurned();
        }

        _burn(address(this), liquidity);

        _safeTransfer(token0, to, amount0);

        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));

        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);

        if (feeOn) {
            kLast = uint256(reserve0) * uint256(reserve1);
        }

        emit Burn(msg.sender, amount0, amount1, to);
    }

    // ============================================================
    // SWAP
    // ============================================================

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        if (amount0Out == 0 && amount1Out == 0) {
            revert InsufficientOutputAmount();
        }

        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        if (amount0Out >= uint256(_reserve0) || amount1Out >= uint256(_reserve1)) {
            revert InsufficientLiquidity();
        }

        address _token0 = token0;

        address _token1 = token1;

        if (to == _token0 || to == _token1) {
            revert InvalidTo();
        }

        if (amount0Out > 0) {
            _safeTransfer(_token0, to, amount0Out);
        }

        if (amount1Out > 0) {
            _safeTransfer(_token1, to, amount1Out);
        }

        if (data.length > 0) {
            IApexV2Callee(to).apexV2Call(msg.sender, amount0Out, amount1Out, data);
        }

        uint256 balance0 = IERC20(_token0).balanceOf(address(this));

        uint256 balance1 = IERC20(_token1).balanceOf(address(this));

        uint256 expectedBalance0 = uint256(_reserve0) - amount0Out;

        uint256 expectedBalance1 = uint256(_reserve1) - amount1Out;

        uint256 amount0In = balance0 > expectedBalance0 ? balance0 - expectedBalance0 : 0;

        uint256 amount1In = balance1 > expectedBalance1 ? balance1 - expectedBalance1 : 0;

        if (amount0In == 0 && amount1In == 0) {
            revert InsufficientInputAmount();
        }

        uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;

        uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;

        if (balance0Adjusted * balance1Adjusted < uint256(_reserve0) * uint256(_reserve1) * 1_000_000) {
            revert K();
        }

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // ============================================================
    // SKIM
    // ============================================================

    function skim(address to) external lock {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));

        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        _safeTransfer(token0, to, balance0 - uint256(reserve0));

        _safeTransfer(token1, to, balance1 - uint256(reserve1));
    }

    // ============================================================
    // SYNC
    // ============================================================

    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
