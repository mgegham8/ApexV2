// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IApexV2ERC20 {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string memory);
    function symbol() external pure returns(string memory);
    function decimals() external pure returns(uint8);

    function totalSupply() external view returns(uint);
    function balanceOf(address owner) external view returns(uint);

    function allowance(address owner, address spender)
        external
        view
        returns(uint);

    function approve(address spender, uint value)
        external
        returns(bool);

    function transfer(address to, uint value)
        external
        returns(bool);

    function transferFrom(address from, address to, uint value)
        external
        returns(bool);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

abstract contract ApexV2ERC20 is IApexV2ERC20 {

    string public constant override name = "Apex V2";
    string public constant override symbol = "APEX";
    uint8 public constant override decimals = 18;

    uint public override totalSupply;

    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    uint public immutable INITIAL_CHAIN_ID;
    bytes32 public immutable INITIAL_DOMAIN_SEPARATOR;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => uint) public nonces;

    error ExpiredPermit();
    error InvalidSignature();
    error ZeroAddress();

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    function DOMAIN_SEPARATOR() public view returns(bytes32) {
        if (block.chainid == INITIAL_CHAIN_ID) {
            return INITIAL_DOMAIN_SEPARATOR;
        }
        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns(bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // ✅ FIXED: թույլ ենք տալիս mint դեպի address(0)
    function _mint(address to, uint value) internal {
        totalSupply += value;
        balanceOf[to] += value;

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        if (from == address(0)) revert ZeroAddress();

        balanceOf[from] -= value;
        totalSupply -= value;

        emit Transfer(from, address(0), value);
    }

    function _transfer(address from, address to, uint value) internal {
        if (to == address(0)) revert ZeroAddress();

        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value)
        external
        override
        returns (bool)
    {
        if (spender == address(0)) revert ZeroAddress();

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value)
        external
        override
        returns (bool)
    {
        uint allowed = allowance[from][msg.sender];

        if (allowed != type(uint).max) {
            allowance[from][msg.sender] = allowed - value;

            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }

        _transfer(from, to, value);

        return true;
    }

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {

        if (deadline < block.timestamp) revert ExpiredPermit();
        if (owner == address(0)) revert ZeroAddress();
        if (spender == address(0)) revert ZeroAddress();

        uint nonce = nonces[owner];

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonce,
                            deadline
                        )
                    )
                )
            );

        address recovered = ecrecover(digest, v, r, s);

        if (recovered == address(0) || recovered != owner)
            revert InvalidSignature();

        nonces[owner] = nonce + 1;
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }
}