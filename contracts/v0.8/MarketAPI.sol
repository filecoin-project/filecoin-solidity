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

import "./types/MarketTypes.sol";
import "./cbor/MarketCbor.sol";
import "./cbor/BytesCbor.sol";
import "./cbor/FilecoinCbor.sol";

import "./types/CommonTypes.sol";
import "./utils/Misc.sol";
import "./utils/Actor.sol";

/// @title This library is a proxy to the singleton Storage Market actor (address: f05). Calling one of its methods will result in a cross-actor call being performed.
/// @author Zondax AG
library MarketAPI {
    using BytesCBOR for bytes;
    using MarketCBOR for *;
    using FilecoinCBOR for *;

    /// @notice Deposits the received value into the balance held in escrow.
    /// @param providerOrClient address that will have its escrow balance increased
    /// @param value amount of funds to be added to the escrow balance
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return data (must be of length 0)
    function addBalance(CommonTypes.FilAddress memory providerOrClient, uint256 value) internal returns (int256, bytes memory) {
        bytes memory raw_request = providerOrClient.serializeAddress();

        (int256 exit_code, bytes memory data) = Actor.callByID(
            MarketTypes.ActorID,
            MarketTypes.AddBalanceMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            value,
            false
        );
        if (data.length != 0) {
            revert Actor.InvalidResponseLength();
        }

        return (exit_code, data);
    }

    /// @notice Attempt to withdraw the specified amount from the balance held in escrow.
    /// @notice If less than the specified amount is available, yields the entire available balance.
    /// @param params `provider_or_client` address, `tokenAmount` to be withdrawn
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return amount that has been withdrawn
    function withdrawBalance(MarketTypes.WithdrawBalanceParams memory params) internal returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = params.serializeWithdrawBalanceParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            MarketTypes.ActorID,
            MarketTypes.WithdrawBalanceMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        CommonTypes.BigInt memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Return the escrow balance and locked amount for an address.
    /// @param addr filecoin address for which escrow balance/locked amount will be queried
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the escrow balance and locked amount for an address.
    function getBalance(CommonTypes.FilAddress memory addr) internal view returns (int256, MarketTypes.GetBalanceReturn memory) {
        bytes memory raw_request = addr.serializeAddress();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(MarketTypes.ActorID, MarketTypes.GetBalanceMethodNum, Misc.CBOR_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeGetBalanceReturn());
        }

        MarketTypes.GetBalanceReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice This will be available after the deal is published (whether or not is is activated) and up until some undefined period after it is terminated.
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the data commitment and size of a deal proposal.
    function getDealDataCommitment(uint64 dealID) internal view returns (int256, MarketTypes.GetDealDataCommitmentReturn memory) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(
            MarketTypes.ActorID,
            MarketTypes.GetDealDataCommitmentMethodNum,
            Misc.CBOR_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeGetDealDataCommitmentReturn());
        }

        MarketTypes.GetDealDataCommitmentReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Returns the client for the specified deal
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the client of a deal proposal.
    function getDealClient(uint64 dealID) internal view returns (int256, uint64) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(MarketTypes.ActorID, MarketTypes.GetDealClientMethodNum, Misc.CBOR_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeUint64());
        }

        uint64 empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Returns the provider for a specified deal
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the provider of a deal proposal.
    function getDealProvider(uint64 dealID) internal view returns (int256, uint64) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(
            MarketTypes.ActorID,
            MarketTypes.GetDealProviderMethodNum,
            Misc.CBOR_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeUint64());
        }

        uint64 empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Returns the label of a storage deal
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the label of a deal
    function getDealLabel(uint64 dealID) internal view returns (int256, CommonTypes.DealLabel memory) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(MarketTypes.ActorID, MarketTypes.GetDealLabelMethodNum, Misc.CBOR_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeDealLabel());
        }

        CommonTypes.DealLabel memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Returns the start epoch and duration(in epochs) of a deal proposal.
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the start epoch and duration (in epochs) of a deal proposal.
    function getDealTerm(uint64 dealID) internal view returns (int256, MarketTypes.GetDealTermReturn memory) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(MarketTypes.ActorID, MarketTypes.GetDealTermMethodNum, Misc.CBOR_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeGetDealTermReturn());
        }

        MarketTypes.GetDealTermReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Returns the total price that will be paid from the client to the provider for this deal.
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the per-epoch price of a deal
    function getDealTotalPrice(uint64 dealID) internal view returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(
            MarketTypes.ActorID,
            MarketTypes.GetDealTotalPriceMethodNum,
            Misc.CBOR_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        CommonTypes.BigInt memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice get the client collateral requirement for a deal
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the client collateral requirement for a deal
    function getDealClientCollateral(uint64 dealID) internal view returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(
            MarketTypes.ActorID,
            MarketTypes.GetDealClientCollateralMethodNum,
            Misc.CBOR_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        CommonTypes.BigInt memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Returns the provider's collateral requirement for a deal
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the provider collateral requirement for a deal
    function getDealProviderCollateral(uint64 dealID) internal view returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(
            MarketTypes.ActorID,
            MarketTypes.GetDealProviderCollateralMethodNum,
            Misc.CBOR_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        CommonTypes.BigInt memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Returns the verified flag for a deal
    /// @notice Note that the source of truth for verified allocations and claims is the verified registry actor.
    /// @param dealID storage deal's id number
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the verified flag for a deal
    function getDealVerified(uint64 dealID) internal view returns (int256, bool) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(
            MarketTypes.ActorID,
            MarketTypes.GetDealVerifiedMethodNum,
            Misc.CBOR_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeBool());
        }

        bool empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Fetches activation state for a deal.
    /// @notice This will be available from when the proposal is published until an undefined period after the deal finishes (either normally or by termination).
    /// @return USR_NOT_FOUND if the deal doesn't exist (yet), or EX_DEAL_EXPIRED if the deal has been removed from state.
    function getDealActivation(uint64 dealID) internal view returns (int256, MarketTypes.GetDealActivationReturn memory) {
        bytes memory raw_request = dealID.serializeDealID();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(
            MarketTypes.ActorID,
            MarketTypes.GetDealActivationMethodNum,
            Misc.CBOR_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeGetDealActivationReturn());
        }

        MarketTypes.GetDealActivationReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Publish a new set of storage deals (not yet included in a sector).
    /// @param params arrays of deals (with their proposals, signatures, etc.)
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return ids of the published deals
    function publishStorageDeals(MarketTypes.PublishStorageDealsParams memory params) internal returns (int256, MarketTypes.PublishStorageDealsReturn memory) {
        bytes memory raw_request = params.serializePublishStorageDealsParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            MarketTypes.ActorID,
            MarketTypes.PublishStorageDealsMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );

        if (exit_code == 0) {
            return (0, result.deserializePublishStorageDealsReturn());
        }

        MarketTypes.PublishStorageDealsReturn memory empty_res;
        return (exit_code, empty_res);
    }
}
