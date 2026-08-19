// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./ApexV2Pair.sol";

/// @title ApexV2Factory
/// @notice Creates and tracks ApexV2 trading pairs and manages protocol fee configuration.
/// @dev Pair addresses are registered bidirectionally in getPair.
contract ApexV2Factory {
    // ============================================================
    // STATE
    // ============================================================

    /// @notice Address receiving protocol fees.
    /// @dev address(0) disables protocol fee collection.
    address public feeTo;

    /// @notice Address authorized to update fee configuration.
    address public feeToSetter;

    /// @notice Returns the pair for any two token addresses.
    /// @dev Both token orderings point to the same pair.
    mapping(address => mapping(address => address)) public getPair;

    /// @notice All pairs created by this factory.
    address[] public allPairs;

    // ============================================================
    // EVENTS
    // ============================================================

    /// @notice Emitted whenever a new pair is created.
    /// @param token0 Lower-address token.
    /// @param token1 Higher-address token.
    /// @param pair Newly deployed pair.
    /// @param pairCount Total number of pairs after creation.
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairCount);

    /// @notice Emitted when the protocol fee recipient changes.
    event FeeToUpdated(address indexed previousFeeTo, address indexed newFeeTo);

    /// @notice Emitted when the fee configuration administrator changes.
    event FeeToSetterUpdated(address indexed previousFeeToSetter, address indexed newFeeToSetter);

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor(address _feeToSetter) {
        require(_feeToSetter != address(0), "ZERO_SETTER");

        feeToSetter = _feeToSetter;
    }

    // ============================================================
    // VIEW
    // ============================================================

    /// @notice Returns the total number of pairs created.
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    // ============================================================
    // CREATE PAIR
    // ============================================================

    /// @notice Creates a trading pair between tokenA and tokenB.
    /// @dev The same pair cannot be created twice regardless of token ordering.
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");

        require(tokenA != address(0) && tokenB != address(0), "ZERO_ADDRESS");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");

        ApexV2Pair newPair = new ApexV2Pair();

        pair = address(newPair);

        newPair.initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // ============================================================
    // FEE RECIPIENT
    // ============================================================

    /// @notice Updates the protocol fee recipient.
    /// @dev Setting feeTo to address(0) intentionally disables protocol fees.
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");

        address previousFeeTo = feeTo;

        // Avoid unnecessary storage writes and misleading events.
        if (_feeTo == previousFeeTo) {
            return;
        }

        feeTo = _feeTo;

        emit FeeToUpdated(previousFeeTo, _feeTo);
    }

    // ============================================================
    // FEE ADMIN
    // ============================================================

    /// @notice Transfers fee configuration authority to a new setter.
    /// @dev Zero-address setter is forbidden to prevent accidental permanent lockout.
    function setFeeToSetter(address _setter) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");

        require(_setter != address(0), "ZERO_SETTER");

        address previousSetter = feeToSetter;

        // No-op transitions are rejected because they provide no useful
        // state change and usually indicate configuration error.
        require(_setter != previousSetter, "SAME_SETTER");

        feeToSetter = _setter;

        emit FeeToSetterUpdated(previousSetter, _setter);
    }
}
