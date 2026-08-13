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

    error Forbidden();
    error AlreadyInitialized();
    error Locked();
    error Overflow();
    error TransferFailed();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error InvalidTo();
    error InsufficientInputAmount();
    error K();

    uint public constant MINIMUM_LIQUIDITY = 1000;

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));

    address public immutable factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;

    bool private initialized;
    uint private unlocked = 1;

    modifier lock() {
        if(unlocked != 1) revert Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        if(msg.sender != factory) revert Forbidden();
        if(initialized) revert AlreadyInitialized();
        token0 = _token0;
        token1 = _token1;
        initialized = true;
    }

    function getReserves() public view returns(uint112, uint112, uint32) {
        return(reserve0, reserve1, blockTimestampLast);
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        if(!success || (data.length != 0 && !abi.decode(data,(bool)))) {
            revert TransferFailed();
        }
    }

    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        if(balance0 > type(uint112).max || balance1 > type(uint112).max) revert Overflow();
        uint32 timestamp = uint32(block.timestamp);
        uint32 timeElapsed = timestamp - blockTimestampLast;
        if(timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = timestamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns(bool feeOn) {
        address feeTo = IApexV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast;
        if(feeOn) {
            if(_kLast != 0) {
                uint rootK = ApexMath.sqrt(uint(_reserve0) * uint(_reserve1));
                uint rootKLast = ApexMath.sqrt(_kLast);
                if(rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = rootK * 5 + rootKLast;
                    uint liquidity = numerator / denominator;
                    if(liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if(_kLast != 0) {
            kLast = 0;
        }
    }

    function mint(address to) external lock returns(uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        if(_totalSupply == 0) {
            uint root = ApexMath.sqrt(amount0 * amount1);
            if(root <= MINIMUM_LIQUIDITY) revert InsufficientLiquidityMinted();
            liquidity = root - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = ApexMath.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        if(liquidity == 0) revert InsufficientLiquidityMinted();
        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        if(feeOn) kLast = uint(reserve0) * uint(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external lock returns(uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;

        if(amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();
        _burn(address(this), liquidity);
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        if(feeOn) kLast = uint(reserve0) * uint(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        if(amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        if(amount0Out >= _reserve0 || amount1Out >= _reserve1) revert InsufficientLiquidity();

        address _token0 = token0;
        address _token1 = token1;
        if(to == _token0 || to == _token1) revert InvalidTo();

        if(amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
        if(amount1Out > 0) _safeTransfer(_token1, to, amount1Out);

        // Ուղղված է՝ apexV2Call (փոքրատառով)
        if(data.length > 0) {
            IApexV2Callee(to).apexV2Call(msg.sender, amount0Out, amount1Out, data);
        }

        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        if(amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        uint balance0Adjusted = balance0 * 1000 - amount0In * 3;
        uint balance1Adjusted = balance1 * 1000 - amount1In * 3;
        if(balance0Adjusted * balance1Adjusted < uint(_reserve0) * uint(_reserve1) * 1000**2) revert K();

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function skim(address to) external lock {
        _safeTransfer(token0, to, IERC20(token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(token1, to, IERC20(token1).balanceOf(address(this)) - reserve1);
    }

    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}