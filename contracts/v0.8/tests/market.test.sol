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

import "../MarketAPI.sol";
import "../types/MarketTypes.sol";
import "../utils/Errors.sol";

/// @notice This file is meant to serve as a deployable contract of the market actor API, as the library by itself is not.
/// @notice It imports the library and create a callable method for each method in the library
/// @author Zondax AG
contract MarketApiTest {
    uint[] public publishedDealIds;

    function add_balance(CommonTypes.FilAddress memory providerOrClient, uint256 value) public payable {
        (int256 exit_code, bytes memory result) = MarketAPI.addBalance(providerOrClient, value);

        Errors.revertOnError(exit_code);
    }

    function withdraw_balance(MarketTypes.WithdrawBalanceParams memory params) public returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = MarketAPI.withdrawBalance(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_balance(CommonTypes.FilAddress memory addr) public view returns (MarketTypes.GetBalanceReturn memory) {
        (int256 exit_code, MarketTypes.GetBalanceReturn memory result) = MarketAPI.getBalance(addr);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_data_commitment(uint64 dealID) public view returns (MarketTypes.GetDealDataCommitmentReturn memory) {
        (int256 exit_code, MarketTypes.GetDealDataCommitmentReturn memory result) = MarketAPI.getDealDataCommitment(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_client(uint64 dealID) public view returns (uint64) {
        (int256 exit_code, uint64 result) = MarketAPI.getDealClient(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_provider(uint64 dealID) public view returns (uint64) {
        (int256 exit_code, uint64 result) = MarketAPI.getDealProvider(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_label(uint64 dealID) public view returns (CommonTypes.DealLabel memory) {
        (int256 exit_code, CommonTypes.DealLabel memory result) = MarketAPI.getDealLabel(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_term(uint64 dealID) public view returns (MarketTypes.GetDealTermReturn memory) {
        (int256 exit_code, MarketTypes.GetDealTermReturn memory result) = MarketAPI.getDealTerm(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_total_price(uint64 dealID) public view returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = MarketAPI.getDealTotalPrice(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_client_collateral(uint64 dealID) public view returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = MarketAPI.getDealClientCollateral(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_provider_collateral(uint64 dealID) public view returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = MarketAPI.getDealProviderCollateral(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_verified(uint64 dealID) public view returns (bool) {
        (int256 exit_code, bool result) = MarketAPI.getDealVerified(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_deal_activation(uint64 dealID) public view returns (MarketTypes.GetDealActivationReturn memory) {
        (int256 exit_code, MarketTypes.GetDealActivationReturn memory result) = MarketAPI.getDealActivation(dealID);

        Errors.revertOnError(exit_code);

        return result;
    }

    function publish_storage_deals(MarketTypes.PublishStorageDealsParams memory params) public returns (MarketTypes.PublishStorageDealsReturn memory) {
        (int256 exit_code, MarketTypes.PublishStorageDealsReturn memory result) = MarketAPI.publishStorageDeals(params);

        Errors.revertOnError(exit_code);

        for (uint i = 0; i < result.ids.length; ++i) {
            publishedDealIds.push(result.ids[i]);
        }

        return result;
    }
}
