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

import "solidity-cborutils/contracts/CBOR.sol";

import "../types/CommonTypes.sol";
import "../types/PowerTypes.sol";
import "../utils/CborDecode.sol";
import "../utils/Misc.sol";
import "../utils/Errors.sol";
import "./BigIntCbor.sol";
import "./BytesCbor.sol";

/// @title This library is a set of functions meant to handle CBOR parameters serialization and return values deserialization for Power actor exported methods.
/// @author Zondax AG
library PowerCBOR {
    using CBOR for CBOR.CBORBuffer;
    using CBORDecoder for bytes;
    using BytesCBOR for bytes;
    using BigIntCBOR for CommonTypes.BigInt;
    using BigIntCBOR for bytes;

    /// @notice serialize CreateMinerParams struct to cbor in order to pass as arguments to the power actor
    /// @param params CreateMinerParams to serialize as cbor
    /// @return cbor serialized data as bytes
    function serializeCreateMinerParams(PowerTypes.CreateMinerParams memory params) internal pure returns (bytes memory) {
        uint256 capacity = 0;
        uint multiaddrsLen = params.multiaddrs.length;

        capacity += Misc.getPrefixSize(5);
        capacity += Misc.getBytesSize(params.owner.data);
        capacity += Misc.getBytesSize(params.worker.data);
        capacity += Misc.getPrefixSize(uint256(params.window_post_proof_type));
        capacity += Misc.getBytesSize(params.peer.data);
        capacity += Misc.getPrefixSize(multiaddrsLen);
        for (uint i = 0; i < multiaddrsLen; i++) {
            capacity += Misc.getBytesSize(params.multiaddrs[i].data);
        }
        CBOR.CBORBuffer memory buf = CBOR.create(capacity);

        buf.startFixedArray(5);
        buf.writeBytes(params.owner.data);
        buf.writeBytes(params.worker.data);
        buf.writeInt64(int64(uint64(params.window_post_proof_type)));
        buf.writeBytes(params.peer.data);
        buf.startFixedArray(uint64(multiaddrsLen));
        for (uint i = 0; i < multiaddrsLen; i++) {
            buf.writeBytes(params.multiaddrs[i].data);
        }

        return buf.data();
    }

    /// @notice deserialize CreateMinerReturn struct from cbor encoded bytes coming from a power actor call
    /// @param rawResp cbor encoded response
    /// @return ret new instance of CreateMinerReturn created based on parsed data
    function deserializeCreateMinerReturn(bytes memory rawResp) internal pure returns (PowerTypes.CreateMinerReturn memory ret) {
        uint byteIdx = 0;
        uint len;

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 2)) {
            revert Errors.InvalidArrayLength(2, len);
        }

        (ret.id_address.data, byteIdx) = rawResp.readBytes(byteIdx);
        (ret.robust_address.data, byteIdx) = rawResp.readBytes(byteIdx);

        return ret;
    }

    /// @notice deserialize MinerRawPowerReturn struct from cbor encoded bytes coming from a power actor call
    /// @param rawResp cbor encoded response
    /// @return ret new instance of MinerRawPowerReturn created based on parsed data
    function deserializeMinerRawPowerReturn(bytes memory rawResp) internal pure returns (PowerTypes.MinerRawPowerReturn memory ret) {
        uint byteIdx = 0;
        uint len;

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 2)) {
            revert Errors.InvalidArrayLength(2, len);
        }

        bytes memory tmp;
        (tmp, byteIdx) = rawResp.readBytes(byteIdx);
        if (tmp.length > 0) {
            ret.raw_byte_power = tmp.deserializeBytesBigInt();
        } else {
            ret.raw_byte_power = CommonTypes.BigInt(new bytes(0), false);
        }

        (ret.meets_consensus_minimum, byteIdx) = rawResp.readBool(byteIdx);

        return ret;
    }
}
