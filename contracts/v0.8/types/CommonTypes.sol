/*******************************************************************************
 *   (c) 2022 Zondax AG
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ********************************************************************************/
//
// THIS CODE WAS SECURITY REVIEWED BY KUDELSKI SECURITY, BUT NOT FORMALLY AUDITED

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;


/// @title Filecoin actors' common types for Solidity.
/// @author Zondax AG
library CommonTypes {
    /// @dev Protocol byte values
    /// @notice These constants represent the byte value for each protocol.
    ///         For more information see the Filecoin documentation: 
    ///         https://docs.filecoin.io/smart-contracts/filecoin-evm-runtime/address-types
    bytes1 constant PROTOCOL_ID = hex"00";
    bytes1 constant PROTOCOL_SECP256K1 = hex"01";
    bytes1 constant PROTOCOL_ACTOR = hex"02";
    bytes1 constant PROTOCOL_BLS = hex"03";
    bytes1 constant PROTOCOL_DELEGATED = hex"04";

    /// @dev EAM actor ID
    /// @notice This constant represents the EAM actor ID.
    bytes1 constant EAM_ID = hex"0a";

    /// @dev Protocols address lengths
    /// @notice These constants represent the address lengths for each protocol.
    ///         For more information see the Filecoin specification: 
    ///         https://spec.filecoin.io/#section-appendix
    uint256 constant MIN_PROTOCOL_ID_ADDRESS_LENGTH = 1;
    uint256 constant MAX_PROTOCOL_ID_ADDRESS_LENGTH = 11;
    uint256 constant PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH = 21; // used for both SECP256K1 and ACTOR
    uint256 constant PROTOCOL_BLS_ADDRESS_LENGTH = 49;
    uint256 constant PROTOCOL_DELEGATED_EAM_ADDRESS_LENGTH = 22;

    /// @dev RecieverHook method number
    /// @notice This constant represents the UniversalReceiverHook method number.
    uint256 constant UniversalReceiverHookMethodNum = 3726118371;

    /// @dev Deal label maximum length in bytes
    /// @notice This constant represents the maximum length of a deal label in bytes.
    uint256 constant MAX_DEAL_LABEL_LENGTH = 256;

    /// @param idx index for the failure in batch
    /// @param code failure code
    struct FailCode {
        uint32 idx;
        uint32 code;
    }

    /// @param success_count total successes in batch
    /// @param fail_codes list of failures code and index for each failure in batch
    struct BatchReturn {
        uint32 success_count;
        FailCode[] fail_codes;
    }

    /// @param type_ asset type
    /// @param payload payload corresponding to asset type
    struct UniversalReceiverParams {
        uint32 type_;
        bytes payload;
    }

    /// @param val contains the actual arbitrary number written as binary
    /// @param neg indicates if val is negative or not
    struct BigInt {
        bytes val;
        bool neg;
    }

    /// @param data filecoin address in bytes format
    struct FilAddress {
        bytes data;
    }

    /// @param data cid in bytes format
    struct Cid {
        bytes data;
    }

    /// @param data deal proposal label in bytes format (it can be utf8 string or arbitrary bytes string).
    /// @param isString indicates if the data is string or raw bytes
    struct DealLabel {
        bytes data;
        bool isString;
    }

    type FilActorId is uint64;

    type ChainEpoch is int64;
}
