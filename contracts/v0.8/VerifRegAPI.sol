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

import "./types/VerifRegTypes.sol";
import "./types/CommonTypes.sol";
import "./cbor/VerifRegCbor.sol";

import "./utils/Actor.sol";
import "./Utils.sol";

/// @title This library is a proxy to a built-in VerifReg actor. Calling one of its methods will result in a cross-actor call being performed.
/// @author Zondax AG
library VerifRegAPI {
    using VerifRegCBOR for *;

    /// @notice get a list of claims corresponding to the requested claim ID for specific provider.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return list of claims corresponding to the requested claim ID for provider
    function getClaims(VerifRegTypes.GetClaimsParams memory params) internal view returns (int256, VerifRegTypes.GetClaimsReturn memory) {
        bytes memory raw_request = params.serializeGetClaimsParams();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(VerifRegTypes.ActorID, VerifRegTypes.GetClaimsMethodNum, Misc.CBOR_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeGetClaimsReturn());
        }

        VerifRegTypes.GetClaimsReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice add a verified Client address to Filecoin Plus program.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function addVerifiedClient(VerifRegTypes.AddVerifiedClientParams memory params) internal returns (int256) {
        bytes memory raw_request = params.serializeAddVerifiedClientParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            VerifRegTypes.ActorID,
            VerifRegTypes.AddVerifiedClientMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );
        if (result.length != 0) {
            revert Actor.InvalidResponseLength();
        }

        return exit_code;
    }

    /// @notice remove the expired DataCap allocations and reclaimed those DataCap token back to Client. If the allocation amount is not specified, all expired DataCap allocation will be removed.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function removeExpiredAllocations(
        VerifRegTypes.RemoveExpiredAllocationsParams memory params
    ) internal returns (int256, VerifRegTypes.RemoveExpiredAllocationsReturn memory) {
        bytes memory raw_request = params.serializeRemoveExpiredAllocationsParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            VerifRegTypes.ActorID,
            VerifRegTypes.RemoveExpiredAllocationsMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );

        if (exit_code == 0) {
            return (0, result.deserializeRemoveExpiredAllocationsReturn());
        }

        VerifRegTypes.RemoveExpiredAllocationsReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice extends the  maximum term of some claims up to the largest value they could have been originally allocated. This method can only be called by the claims' client.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function extendClaimTerms(VerifRegTypes.ClaimTerm[] memory claimTerms) internal returns (int256, CommonTypes.BatchReturn memory) {
        bytes memory raw_request = claimTerms.serializeExtendClaimTermsParams();
        (int256 exit_code, bytes memory result) = Actor.callByID(
            VerifRegTypes.ActorID,
            VerifRegTypes.ExtendClaimTermsMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );
        if (exit_code == 0) {
            return (0, result.deserializeBatchReturn());
        }
        CommonTypes.BatchReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice remove a claim with its maximum term has elapsed.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function removeExpiredClaims(
        VerifRegTypes.RemoveExpiredClaimsParams memory params
    ) internal returns (int256, VerifRegTypes.RemoveExpiredClaimsReturn memory) {
        bytes memory raw_request = params.serializeRemoveExpiredClaimsParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            VerifRegTypes.ActorID,
            VerifRegTypes.RemoveExpiredClaimsMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );

        if (exit_code == 0) {
            return (0, result.deserializeRemoveExpiredClaimsReturn());
        }

        VerifRegTypes.RemoveExpiredClaimsReturn memory empty_res;
        return (exit_code, empty_res);
    }
}
