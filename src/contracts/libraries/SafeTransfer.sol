// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

library SafeTransfer {

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(
                    0x23b872dd,
                    from,
                    to,
                    value
                )
            );

        require(success, "TRANSFER_FROM_FAILED");

        require(
            data.length == 0 || (data.length == 32 && abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    )
        internal
    {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(
                    0xa9059cbb,
                    to,
                    value
                )
            );

        require(success, "TRANSFER_FAILED");

        require(
            data.length == 0 || (data.length == 32 && abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }
}