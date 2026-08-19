// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract WETH9 {
    string public name =
        "Wrapped Ether";

    string public symbol =
        "WETH";

    uint8 public constant decimals =
        18;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    event Deposit(
        address indexed dst,
        uint256 wad
    );

    event Withdrawal(
        address indexed src,
        uint256 wad
    );

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

    receive()
        external
        payable
    {
        deposit();
    }

    function deposit()
        public
        payable
    {
        balanceOf[msg.sender] +=
            msg.value;

        emit Deposit(
            msg.sender,
            msg.value
        );
    }

    function withdraw(
        uint256 wad
    )
        public
    {
        uint256 balance =
            balanceOf[msg.sender];

        require(
            balance >= wad,
            "WETH: balance"
        );

        unchecked {
            balanceOf[msg.sender] =
                balance - wad;
        }

        (
            bool success,
        ) =
            payable(msg.sender).call{
                value: wad
            }("");

        require(
            success,
            "WETH: ETH_TRANSFER_FAILED"
        );

        emit Withdrawal(
            msg.sender,
            wad
        );
    }

    function transfer(
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        require(
            to != address(0),
            "WETH: zero address"
        );

        uint256 balance =
            balanceOf[msg.sender];

        require(
            balance >= value,
            "WETH: balance"
        );

        unchecked {
            balanceOf[msg.sender] =
                balance - value;
        }

        balanceOf[to] +=
            value;

        emit Transfer(
            msg.sender,
            to,
            value
        );

        return true;
    }

    function approve(
        address spender,
        uint256 value
    )
        public
        returns (bool)
    {
        allowance[msg.sender][spender] =
            value;

        emit Approval(
            msg.sender,
            spender,
            value
        );

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        require(
            to != address(0),
            "WETH: zero address"
        );

        uint256 balance =
            balanceOf[from];

        require(
            balance >= value,
            "WETH: balance"
        );

        if (
            from != msg.sender
        ) {
            uint256 allowed =
                allowance[from][msg.sender];

            require(
                allowed >= value,
                "WETH: allowance"
            );

            if (
                allowed !=
                type(uint256).max
            ) {
                unchecked {
                    allowance[from][msg.sender] =
                        allowed - value;
                }

                emit Approval(
                    from,
                    msg.sender,
                    allowance[from][msg.sender]
                );
            }
        }

        unchecked {
            balanceOf[from] =
                balance - value;
        }

        balanceOf[to] +=
            value;

        emit Transfer(
            from,
            to,
            value
        );

        return true;
    }
}