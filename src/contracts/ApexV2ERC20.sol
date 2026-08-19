// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IApexV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

abstract contract ApexV2ERC20 is IApexV2ERC20 {
    // ============================================================
    // METADATA
    // ============================================================

    string public constant override name = "Apex V2";

    string public constant override symbol = "APEX";

    uint8 public constant override decimals = 18;

    // ============================================================
    // ERC20 STORAGE
    // ============================================================

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    // ============================================================
    // EIP-2612
    // ============================================================

    uint256 public immutable INITIAL_CHAIN_ID;

    bytes32 public immutable INITIAL_DOMAIN_SEPARATOR;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private constant NAME_HASH = keccak256(bytes("Apex V2"));

    bytes32 private constant VERSION_HASH = keccak256(bytes("1"));

    /*
     * secp256k1 curve order / 2.
     *
     * Rejecting high-s signatures prevents signature malleability.
     */
    uint256 private constant SECP256K1N_DIV_2 = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    mapping(address => uint256) public nonces;

    // ============================================================
    // ERRORS
    // ============================================================

    error ExpiredPermit();
    error InvalidSignature();
    error ZeroAddress();

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;

        INITIAL_DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    // ============================================================
    // DOMAIN SEPARATOR
    // ============================================================

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (block.chainid == INITIAL_CHAIN_ID) {
            return INITIAL_DOMAIN_SEPARATOR;
        }

        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, block.chainid, address(this)));
    }

    // ============================================================
    // MINT
    // ============================================================

    /*
     * Minting to address(0) is intentionally supported.
     *
     * ApexV2Pair uses this to permanently lock MINIMUM_LIQUIDITY.
     */
    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        balanceOf[to] += value;

        emit Transfer(address(0), to, value);
    }

    // ============================================================
    // BURN
    // ============================================================

    function _burn(address from, uint256 value) internal {
        if (from == address(0)) {
            revert ZeroAddress();
        }

        balanceOf[from] -= value;

        totalSupply -= value;

        emit Transfer(from, address(0), value);
    }

    // ============================================================
    // TRANSFER INTERNAL
    // ============================================================

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0) || to == address(0)) {
            revert ZeroAddress();
        }

        balanceOf[from] -= value;

        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);
    }

    // ============================================================
    // APPROVE
    // ============================================================

    function approve(address spender, uint256 value) external override returns (bool) {
        if (spender == address(0)) {
            revert ZeroAddress();
        }

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    // ============================================================
    // TRANSFER
    // ============================================================

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    // ============================================================
    // TRANSFER FROM
    // ============================================================

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - value;

            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }

        _transfer(from, to, value);

        return true;
    }

    // ============================================================
    // PERMIT
    // ============================================================

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        override
    {
        if (deadline < block.timestamp) {
            revert ExpiredPermit();
        }

        if (owner == address(0) || spender == address(0)) {
            revert ZeroAddress();
        }

        /*
         * ECDSA canonical signature validation.
         */
        if (v != 27 && v != 28) {
            revert InvalidSignature();
        }

        if (uint256(s) > SECP256K1N_DIV_2) {
            revert InvalidSignature();
        }

        uint256 nonce = nonces[owner];

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));

        address recovered = ecrecover(digest, v, r, s);

        if (recovered == address(0) || recovered != owner) {
            revert InvalidSignature();
        }

        /*
         * State changes only after signature verification.
         */
        unchecked {
            nonces[owner] = nonce + 1;
        }

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }
}
