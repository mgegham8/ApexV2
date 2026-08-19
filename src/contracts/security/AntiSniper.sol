// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract AntiSniper {
    // ============================================================
    // ERRORS
    // ============================================================

    error NotOwner();
    error ZeroAddress();
    error AlreadyStarted();
    error ProtectionNotEnabled();
    error InvalidProtectionBlocks();
    error InvalidMaxBuy();
    error InvalidMaxWallet();
    error MaxBuyGreaterThanMaxWallet();
    error Blacklisted();
    error MaxBuyExceeded();
    error MaxWalletExceeded();
    error WalletBalanceOverflow();
    error SameOwner();

    // ============================================================
    // STORAGE
    // ============================================================

    address public owner;

    bool public protectionEnabled;
    bool public launchStarted;

    uint256 public launchBlock;
    uint256 public protectionBlocks;

    uint256 public maxBuyAmount;
    uint256 public maxWalletAmount;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    // ============================================================
    // EVENTS
    // ============================================================

    event LaunchStarted(
        uint256 indexed blockNumber, uint256 protectionBlocks, uint256 maxBuyAmount, uint256 maxWalletAmount
    );

    event ProtectionDisabled();

    event BlacklistUpdated(address indexed account, bool status);

    event WhitelistUpdated(address indexed account, bool status);

    event LimitsUpdated(uint256 maxBuy, uint256 maxWallet);

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

    constructor() {
        owner = msg.sender;
    }

    // ============================================================
    // LAUNCH
    // ============================================================

    function startLaunch(uint256 _protectionBlocks, uint256 _maxBuyAmount, uint256 _maxWalletAmount)
        external
        onlyOwner
    {
        if (launchStarted) {
            revert AlreadyStarted();
        }

        if (_protectionBlocks == 0) {
            revert InvalidProtectionBlocks();
        }

        if (_maxBuyAmount == 0) {
            revert InvalidMaxBuy();
        }

        if (_maxWalletAmount == 0) {
            revert InvalidMaxWallet();
        }

        if (_maxBuyAmount > _maxWalletAmount) {
            revert MaxBuyGreaterThanMaxWallet();
        }

        launchBlock = block.number;

        protectionBlocks = _protectionBlocks;

        maxBuyAmount = _maxBuyAmount;

        maxWalletAmount = _maxWalletAmount;

        launchStarted = true;

        protectionEnabled = true;

        emit LaunchStarted(block.number, _protectionBlocks, _maxBuyAmount, _maxWalletAmount);
    }

    // ============================================================
    // PROTECTION
    // ============================================================

    function disableProtection() external onlyOwner {
        if (!protectionEnabled) {
            revert ProtectionNotEnabled();
        }

        protectionEnabled = false;

        emit ProtectionDisabled();
    }

    // ============================================================
    // BLACKLIST
    // ============================================================

    function setBlacklist(address account, bool status) external onlyOwner {
        if (account == address(0)) {
            revert ZeroAddress();
        }

        blacklist[account] = status;

        emit BlacklistUpdated(account, status);
    }

    // ============================================================
    // WHITELIST
    // ============================================================

    function setWhitelist(address account, bool status) external onlyOwner {
        if (account == address(0)) {
            revert ZeroAddress();
        }

        whitelist[account] = status;

        emit WhitelistUpdated(account, status);
    }

    // ============================================================
    // LIMITS
    // ============================================================

    function setLimits(uint256 _maxBuyAmount, uint256 _maxWalletAmount) external onlyOwner {
        if (_maxBuyAmount == 0) {
            revert InvalidMaxBuy();
        }

        if (_maxWalletAmount == 0) {
            revert InvalidMaxWallet();
        }

        if (_maxBuyAmount > _maxWalletAmount) {
            revert MaxBuyGreaterThanMaxWallet();
        }

        maxBuyAmount = _maxBuyAmount;

        maxWalletAmount = _maxWalletAmount;

        emit LimitsUpdated(_maxBuyAmount, _maxWalletAmount);
    }

    // ============================================================
    // BUY VALIDATION
    // ============================================================

    function checkBuy(address buyer, uint256 amount, uint256 currentWalletBalance) external view returns (bool) {
        if (buyer == address(0)) {
            revert ZeroAddress();
        }

        /*
         * Protection disabled:
         * no launch restrictions apply.
         */
        if (!protectionEnabled) {
            return true;
        }

        /*
         * Whitelisted accounts bypass launch restrictions.
         */
        if (whitelist[buyer]) {
            return true;
        }

        if (blacklist[buyer]) {
            revert Blacklisted();
        }

        /*
         * Protection automatically stops applying once the
         * configured launch block window has passed.
         *
         * Important:
         * The old implementation reverted here, effectively
         * blocking every normal buy after protection expired.
         */
        if (!_isProtectionActive()) {
            return true;
        }

        if (amount > maxBuyAmount) {
            revert MaxBuyExceeded();
        }

        if (amount > type(uint256).max - currentWalletBalance) {
            revert WalletBalanceOverflow();
        }

        if (currentWalletBalance + amount > maxWalletAmount) {
            revert MaxWalletExceeded();
        }

        return true;
    }

    // ============================================================
    // VIEW HELPERS
    // ============================================================

    function isProtectionActive() external view returns (bool) {
        return _isProtectionActive();
    }

    function protectionEndBlock() external view returns (uint256) {
        if (!launchStarted) {
            return 0;
        }

        return launchBlock + protectionBlocks;
    }

    function _isProtectionActive() internal view returns (bool) {
        if (!launchStarted || !protectionEnabled) {
            return false;
        }

        return block.number <= launchBlock + protectionBlocks;
    }

    // ============================================================
    // OWNERSHIP
    // ============================================================

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        if (newOwner == owner) {
            revert SameOwner();
        }

        address oldOwner = owner;

        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
