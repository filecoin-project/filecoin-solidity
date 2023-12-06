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
// THIS CODE WAS SECURITY REVIEWED BY KUDELSKI SECURITY, BUT NOT FORMALLY AUDITED

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "../types/CommonTypes.sol";
import "../utils/Leb128.sol";
import "@ensdomains/buffer/contracts/Buffer.sol";

/// @notice This library is a set a functions that allows to handle filecoin addresses conversions and validations
/// @author Zondax AG
library FilAddresses {
    using Buffer for Buffer.buffer;

    error InvalidAddress();

    /// @notice allow to get a FilAddress from an eth address
    /// @param addr eth address to convert
    /// @return new filecoin address
    function fromEthAddress(address addr) internal pure returns (CommonTypes.FilAddress memory) {
        return CommonTypes.FilAddress(abi.encodePacked(CommonTypes.PROTOCOL_DELEGATED, CommonTypes.EAM_ID, addr));
    }

    /// @notice allow to get a eth address from 040a type FilAddress made above
    /// @param addr FilAddress to convert
    /// @return new eth address
    function toEthAddress(CommonTypes.FilAddress memory addr) internal pure returns (address) {
        if (
            addr.data[0] != CommonTypes.PROTOCOL_DELEGATED || addr.data[1] != CommonTypes.EAM_ID
                || addr.data.length != CommonTypes.PROTOCOL_DELEGATED_EAM_ADDRESS_LENGTH
        ) {
            revert InvalidAddress();
        }
        bytes memory filAddress = addr.data;
        bytes20 ethAddress;

        assembly {
            ethAddress := mload(add(filAddress, 0x22))
        }

        return address(ethAddress);
    }

    /// @notice allow to create a Filecoin address from an actorID
    /// @param actorID uint64 actorID
    /// @return address filecoin address
    function fromActorID(uint64 actorID) internal pure returns (CommonTypes.FilAddress memory) {
        Buffer.buffer memory result = Leb128.encodeUnsignedLeb128FromUInt64(actorID);
        return CommonTypes.FilAddress(abi.encodePacked(CommonTypes.PROTOCOL_ID, result.buf));
    }

    /// @notice allow to create a Filecoin address from bytes
    /// @param data address in bytes format
    /// @return filecoin address
    function fromBytes(bytes memory data) internal pure returns (CommonTypes.FilAddress memory) {
        CommonTypes.FilAddress memory newAddr = CommonTypes.FilAddress(data);
        if (!validate(newAddr)) {
            revert InvalidAddress();
        }

        return newAddr;
    }

    /// @notice allow to validate if an address is valid or not
    /// @dev we are only validating known address types. If the type is not known, the default value is true
    /// @param addr the filecoin address to validate
    /// @return whether the address is valid or not
    function validate(CommonTypes.FilAddress memory addr) internal pure returns (bool) {
        if (addr.data[0] == CommonTypes.PROTOCOL_ID) {
            return (
                addr.data.length > CommonTypes.MIN_PROTOCOL_ID_ADDRESS_LENGTH
                    && addr.data.length <= CommonTypes.MAX_PROTOCOL_ID_ADDRESS_LENGTH
            );
        } else if (addr.data[0] == CommonTypes.PROTOCOL_SECP256K1 || addr.data[0] == CommonTypes.PROTOCOL_ACTOR) {
            return addr.data.length == CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH;
        } else if (addr.data[0] == CommonTypes.PROTOCOL_BLS) {
            return addr.data.length == CommonTypes.PROTOCOL_BLS_ADDRESS_LENGTH;
        } else if (addr.data[0] == CommonTypes.PROTOCOL_DELEGATED && addr.data[1] == CommonTypes.EAM_ID) {
            return addr.data.length == CommonTypes.PROTOCOL_DELEGATED_EAM_ADDRESS_LENGTH;
        }

        return addr.data.length <= 256;
    }
}
