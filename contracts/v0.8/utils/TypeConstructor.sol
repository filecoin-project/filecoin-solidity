// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../types/CommonTypes.sol";

/// @title TypeConstructor
/// @notice This library is a set a functions that allows to construct filecoin common types from solidity
/// @author Filecoin Project
library TypeConstructor {
    error InvalidLength();

    /// @notice Converts a string to a filecoin cid common type
    /// @param cid The CIDv1/CIDv0 cid string
    function cidToBytes(string calldata cid) external pure returns (CommonTypes.Cid memory) {}

    /// @notice Converts bytes to filecoin common type DealLabel
    /// @param data The data must be no longer than 32 bytes
    function bytesToDealLabel(bytes calldata data) external pure returns (CommonTypes.DealLabel memory) {
        if (data.length > 32) {
            revert InvalidLength();
        }
        return CommonTypes.DealLabel(data, false);
    }

    /// @notice Converts a string to filecoin common type DealLabel
    /// @param data UTF-8 string
    function stringToDealLabel(string calldata data) external pure returns (CommonTypes.DealLabel memory) {}
}
