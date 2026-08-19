// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IWETH9 {
    // =========================
    // ERC20 METADATA
    // =========================

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // =========================
    // ERC20 DATA
    // =========================

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    // =========================
    // ERC20 FUNCTIONS
    // =========================

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // =========================
    // WETH FUNCTIONS
    // =========================

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    // =========================
    // EVENTS
    // =========================

    event Deposit(address indexed dst, uint256 wad);

    event Withdrawal(address indexed src, uint256 wad);

    event Transfer(address indexed src, address indexed dst, uint256 wad);

    event Approval(address indexed src, address indexed guy, uint256 wad);
}
