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

import "../types/VerifRegTypes.sol";
import "../types/CommonTypes.sol";
import "../VerifRegAPI.sol";
import "../utils/Errors.sol";

/// @notice This file is meant to serve as a deployable contract of the verified registry actor API, as the library by itself is not.
/// @notice It imports the library and create a callable method for each method in the library
/// @author Zondax AG
contract VerifRegApiTest {
    function get_claims(VerifRegTypes.GetClaimsParams memory params) public view returns (VerifRegTypes.GetClaimsReturn memory) {
        (int256 exit_code, VerifRegTypes.GetClaimsReturn memory result) = VerifRegAPI.getClaims(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function add_verified_client(VerifRegTypes.AddVerifiedClientParams memory params) public {
        int256 exit_code = VerifRegAPI.addVerifiedClient(params);

        Errors.revertOnError(exit_code);
    }

    function remove_expired_allocations(
        VerifRegTypes.RemoveExpiredAllocationsParams memory params
    ) public returns (VerifRegTypes.RemoveExpiredAllocationsReturn memory) {
        (int256 exit_code, VerifRegTypes.RemoveExpiredAllocationsReturn memory result) = VerifRegAPI.removeExpiredAllocations(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function extend_claim_terms(VerifRegTypes.ExtendClaimTermsParams memory params) public returns (CommonTypes.BatchReturn memory) {
        (int256 exit_code, CommonTypes.BatchReturn memory result) = VerifRegAPI.extendClaimTerms(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function remove_expired_claims(VerifRegTypes.RemoveExpiredClaimsParams memory params) public returns (VerifRegTypes.RemoveExpiredClaimsReturn memory) {
        (int256 exit_code, VerifRegTypes.RemoveExpiredClaimsReturn memory result) = VerifRegAPI.removeExpiredClaims(params);

        Errors.revertOnError(exit_code);

        return result;
    }
}
