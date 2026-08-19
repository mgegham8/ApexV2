// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IApexLaunchRouter {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IApexLaunchFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IApexLaunchVesting {
    function createVesting(address user, uint256 amount, uint256 startTime, uint256 cliff, uint256 duration) external;
}

contract ApexLaunchController is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============================================================
    // ERRORS
    // ============================================================

    error NotOwner();
    error NotPendingOwner();

    error ZeroToken();
    error ZeroRouter();
    error ZeroFactory();
    error ZeroVesting();

    error TokenHasNoCode();
    error RouterHasNoCode();
    error FactoryHasNoCode();
    error VestingHasNoCode();

    error ZeroWETH();
    error WETHHasNoCode();

    error AlreadyLaunched();
    error PairAlreadyExists();

    error ZeroTokenAmount();
    error ZeroETHAmount();
    error WrongETHAmount();
    error InsufficientTokenBalance();

    error NoLiquidity();
    error PairNotCreated();
    error UnexpectedPair();

    error ZeroUser();
    error ZeroAmount();
    error ZeroDuration();
    error InvalidCliff();

    error ZeroOwner();
    error SameOwner();

    error UnauthorizedETHSender();

    // ============================================================
    // STORAGE
    // ============================================================

    address public owner;
    address public pendingOwner;

    address public immutable token;
    address public immutable router;
    address public immutable factory;
    address public immutable vesting;

    address public lpToken;

    bool public launched;

    // ============================================================
    // EVENTS
    // ============================================================

    event Launched(address indexed pair, uint256 amountToken, uint256 amountETH, uint256 liquidity);

    event VestingCreated(address indexed user, uint256 amount, uint256 cliff, uint256 duration);

    event OwnershipTransferStarted(address indexed oldOwner, address indexed pendingOwner);

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // ============================================================
    // MODIFIERS
    // ============================================================

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        _;
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor(address _token, address _router, address _factory, address _vesting) {
        if (_token == address(0)) {
            revert ZeroToken();
        }

        if (_router == address(0)) {
            revert ZeroRouter();
        }

        if (_factory == address(0)) {
            revert ZeroFactory();
        }

        if (_vesting == address(0)) {
            revert ZeroVesting();
        }

        if (_token.code.length == 0) {
            revert TokenHasNoCode();
        }

        if (_router.code.length == 0) {
            revert RouterHasNoCode();
        }

        if (_factory.code.length == 0) {
            revert FactoryHasNoCode();
        }

        if (_vesting.code.length == 0) {
            revert VestingHasNoCode();
        }

        owner = msg.sender;

        token = _token;
        router = _router;
        factory = _factory;
        vesting = _vesting;
    }

    // ============================================================
    // RECEIVE ETH
    // ============================================================

    receive() external payable {
        /*
         * Router may refund excess ETH during addLiquidityETH().
         * Arbitrary direct ETH transfers are rejected.
         */
        if (msg.sender != router) {
            revert UnauthorizedETHSender();
        }
    }

    // ============================================================
    // LAUNCH
    // ============================================================

    function launch(address weth, uint256 tokenAmount, uint256 ethAmount) external payable onlyOwner nonReentrant {
        if (launched) {
            revert AlreadyLaunched();
        }

        if (weth == address(0)) {
            revert ZeroWETH();
        }

        if (weth.code.length == 0) {
            revert WETHHasNoCode();
        }

        if (tokenAmount == 0) {
            revert ZeroTokenAmount();
        }

        if (ethAmount == 0) {
            revert ZeroETHAmount();
        }

        if (msg.value != ethAmount) {
            revert WrongETHAmount();
        }

        if (IERC20(token).balanceOf(address(this)) < tokenAmount) {
            revert InsufficientTokenBalance();
        }

        /*
         * A launch controller should create the INITIAL pool.
         * Do not silently join an already-existing market whose
         * price may already have been manipulated.
         */
        if (IApexLaunchFactory(factory).getPair(token, weth) != address(0)) {
            revert PairAlreadyExists();
        }

        /*
         * Set before external Router call as a reentrancy-safe
         * state transition. Any downstream revert rolls this back.
         */
        launched = true;

        IERC20(token).forceApprove(router, tokenAmount);

        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = IApexLaunchRouter(router)
        .addLiquidityETH{value: ethAmount}(
            token, tokenAmount, 0, 0, address(this), block.timestamp + 1 hours
        );

        if (liquidity == 0) {
            revert NoLiquidity();
        }

        address pair = IApexLaunchFactory(factory).getPair(token, weth);

        if (pair == address(0)) {
            revert PairNotCreated();
        }

        lpToken = pair;

        /*
         * Remove residual approval after launch.
         */
        IERC20(token).forceApprove(router, 0);

        emit Launched(pair, amountToken, amountETH, liquidity);
    }

    // ============================================================
    // VESTING
    // ============================================================

    function createVesting(address user, uint256 amount, uint256 cliff, uint256 duration)
        external
        onlyOwner
        nonReentrant
    {
        if (user == address(0)) {
            revert ZeroUser();
        }

        if (amount == 0) {
            revert ZeroAmount();
        }

        if (duration == 0) {
            revert ZeroDuration();
        }

        if (cliff > duration) {
            revert InvalidCliff();
        }

        IApexLaunchVesting(vesting).createVesting(user, amount, block.timestamp, cliff, duration);

        emit VestingCreated(user, amount, cliff, duration);
    }

    // ============================================================
    // OWNERSHIP
    // ============================================================

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroOwner();
        }

        if (newOwner == owner) {
            revert SameOwner();
        }

        pendingOwner = newOwner;

        emit OwnershipTransferStarted(owner, newOwner);
    }

    function acceptOwnership() external {
        address newOwner = pendingOwner;

        if (msg.sender != newOwner) {
            revert NotPendingOwner();
        }

        address oldOwner = owner;

        owner = newOwner;

        pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
