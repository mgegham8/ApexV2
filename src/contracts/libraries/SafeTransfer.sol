// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

library SafeTransfer {
    error TransferFailed();
    error TransferFromFailed();
    error TokenHasNoCode();

    bytes4 private constant TRANSFER_SELECTOR =
        0xa9059cbb;

    bytes4 private constant TRANSFER_FROM_SELECTOR =
        0x23b872dd;

    function safeTransfer(
        address token,
        address to,
        uint256 value
    )
        internal
    {
        if (token.code.length == 0) {
            revert TokenHasNoCode();
        }

        (
            bool success,
            bytes memory data
        ) =
            token.call(
                abi.encodeWithSelector(
                    TRANSFER_SELECTOR,
                    to,
                    value
                )
            );

        if (!success) {
            revert TransferFailed();
        }

        if (!_isSuccessfulReturnData(data)) {
            revert TransferFailed();
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        if (token.code.length == 0) {
            revert TokenHasNoCode();
        }

        (
            bool success,
            bytes memory data
        ) =
            token.call(
                abi.encodeWithSelector(
                    TRANSFER_FROM_SELECTOR,
                    from,
                    to,
                    value
                )
            );

        if (!success) {
            revert TransferFromFailed();
        }

        if (!_isSuccessfulReturnData(data)) {
            revert TransferFromFailed();
        }
    }

    function _isSuccessfulReturnData(
        bytes memory data
    )
        private
        pure
        returns (bool)
    {
        if (data.length == 0) {
            return true;
        }

        if (data.length != 32) {
            return false;
        }

        uint256 result;

        assembly ("memory-safe") {
            result := mload(
                add(data, 0x20)
            )
        }

        return result == 1;
    }
}