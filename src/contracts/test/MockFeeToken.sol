// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract MockFeeToken {
    string public name =
        "Fee Token";

    string public symbol =
        "FEE";

    uint8 public constant decimals =
        18;

    uint256 public totalSupply;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    uint256 public constant FEE =
        1; // 1%

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        require(
            to != address(0),
            "ZERO_ADDRESS"
        );

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
        _transfer(
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
        uint256 allowed =
            allowance[from][msg.sender];

        require(
            allowed >= amount,
            "ALLOWANCE_LOW"
        );

        if (
            allowed !=
            type(uint256).max
        ) {
            unchecked {
                allowance[from][msg.sender] =
                    allowed - amount;
            }

            emit Approval(
                from,
                msg.sender,
                allowance[from][msg.sender]
            );
        }

        _transfer(
            from,
            to,
            amount
        );

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        require(
            to != address(0),
            "ZERO_ADDRESS"
        );

        uint256 fromBalance =
            balanceOf[from];

        require(
            fromBalance >= amount,
            "BALANCE_LOW"
        );

        uint256 feeAmount =
            amount * FEE / 100;

        uint256 sendAmount =
            amount - feeAmount;

        unchecked {
            balanceOf[from] =
                fromBalance - amount;
        }

        balanceOf[to] +=
            sendAmount;

        emit Transfer(
            from,
            to,
            sendAmount
        );

        if (
            feeAmount != 0
        ) {
            totalSupply -=
                feeAmount;

            emit Transfer(
                from,
                address(0),
                feeAmount
            );
        }
    }
}