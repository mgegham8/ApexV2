// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract MaliciousERC20 {
    string public name =
        "Malicious";

    string public symbol =
        "BAD";

    uint8 public constant decimals =
        18;

    uint256 public totalSupply;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    bool public failTransferFrom;
    bool public failTransfer;

    bool public revertTransferFrom;
    bool public revertTransfer;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    constructor() {
        _mint(
            msg.sender,
            1_000_000 ether
        );
    }

    function _mint(
        address to,
        uint256 amount
    )
        internal
    {
        balanceOf[to] +=
            amount;

        totalSupply +=
            amount;

        emit Transfer(
            address(0),
            to,
            amount
        );
    }

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        _mint(
            to,
            amount
        );
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        allowance[msg.sender][spender] =
            amount;

        emit Approval(
            msg.sender,
            spender,
            amount
        );

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        if (revertTransfer) {
            revert(
                "MALICIOUS_TRANSFER_REVERT"
            );
        }

        if (failTransfer) {
            return false;
        }

        require(
            balanceOf[msg.sender] >= amount,
            "INSUFFICIENT_BALANCE"
        );

        balanceOf[msg.sender] -=
            amount;

        balanceOf[to] +=
            amount;

        emit Transfer(
            msg.sender,
            to,
            amount
        );

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
        if (revertTransferFrom) {
            revert(
                "MALICIOUS_TRANSFERFROM_REVERT"
            );
        }

        if (failTransferFrom) {
            return false;
        }

        uint256 allowed =
            allowance[from][msg.sender];

        require(
            allowed >= amount,
            "INSUFFICIENT_ALLOWANCE"
        );

        require(
            balanceOf[from] >= amount,
            "INSUFFICIENT_BALANCE"
        );

        if (
            allowed !=
            type(uint256).max
        ) {
            allowance[from][msg.sender] =
                allowed -
                amount;

            emit Approval(
                from,
                msg.sender,
                allowance[from][msg.sender]
            );
        }

        balanceOf[from] -=
            amount;

        balanceOf[to] +=
            amount;

        emit Transfer(
            from,
            to,
            amount
        );

        return true;
    }

    function setFailTransferFrom(
        bool value
    )
        external
    {
        failTransferFrom =
            value;
    }

    function setFailTransfer(
        bool value
    )
        external
    {
        failTransfer =
            value;
    }

    function setRevertTransferFrom(
        bool value
    )
        external
    {
        revertTransferFrom =
            value;
    }

    function setRevertTransfer(
        bool value
    )
        external
    {
        revertTransfer =
            value;
    }
}