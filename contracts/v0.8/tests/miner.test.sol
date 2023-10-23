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

import "../MinerAPI.sol";
import "../types/MinerTypes.sol";
import "../utils/Errors.sol";

/// @notice This file is meant to serve as a deployable contract of the miner actor API, as the library by itself is not.
/// @notice It imports the library and create a callable method for each method in the library
/// @author Zondax AG
contract MinerApiTest {
    function get_owner(CommonTypes.FilActorId target) public view returns (MinerTypes.GetOwnerReturn memory) {
        (int256 exit_code, MinerTypes.GetOwnerReturn memory result) = MinerAPI.getOwner(target);

        Errors.revertOnError(exit_code);

        return result;
    }

    function change_owner_address(CommonTypes.FilActorId target, CommonTypes.FilAddress memory addr) public {
        int256 exit_code = MinerAPI.changeOwnerAddress(target, addr);

        Errors.revertOnError(exit_code);
    }

    function is_controlling_address(CommonTypes.FilActorId target, CommonTypes.FilAddress memory addr) public view returns (bool) {
        (int256 exit_code, bool result) = MinerAPI.isControllingAddress(target, addr);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_sector_size(CommonTypes.FilActorId target) public view returns (uint64) {
        (int256 exit_code, uint64 result) = MinerAPI.getSectorSize(target);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_available_balance(CommonTypes.FilActorId target) public view returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = MinerAPI.getAvailableBalance(target);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_vesting_funds(CommonTypes.FilActorId target) public view returns (MinerTypes.GetVestingFundsReturn memory) {
        (int256 exit_code, MinerTypes.GetVestingFundsReturn memory result) = MinerAPI.getVestingFunds(target);

        Errors.revertOnError(exit_code);

        return result;
    }

    function change_beneficiary(CommonTypes.FilActorId target, MinerTypes.ChangeBeneficiaryParams memory params) public {
        int256 exit_code = MinerAPI.changeBeneficiary(target, params);

        Errors.revertOnError(exit_code);
    }

    function get_beneficiary(CommonTypes.FilActorId target) public view returns (MinerTypes.GetBeneficiaryReturn memory) {
        (int256 exit_code, MinerTypes.GetBeneficiaryReturn memory result) = MinerAPI.getBeneficiary(target);

        Errors.revertOnError(exit_code);

        return result;
    }

    function change_worker_address(CommonTypes.FilActorId target, MinerTypes.ChangeWorkerAddressParams memory params) public {
        int256 exit_code = MinerAPI.changeWorkerAddress(target, params);

        Errors.revertOnError(exit_code);
    }

    function change_peer_id(CommonTypes.FilActorId target, CommonTypes.FilAddress memory newId) public {
        int256 exit_code = MinerAPI.changePeerId(target, newId);

        Errors.revertOnError(exit_code);
    }

    function change_multiaddresses(CommonTypes.FilActorId target, MinerTypes.ChangeMultiaddrsParams memory params) public {
        int256 exit_code = MinerAPI.changeMultiaddresses(target, params);

        Errors.revertOnError(exit_code);
    }

    function repay_debt(CommonTypes.FilActorId target) public {
        int256 exit_code = MinerAPI.repayDebt(target);

        Errors.revertOnError(exit_code);
    }

    function confirm_change_worker_address(CommonTypes.FilActorId target) public {
        int256 exit_code = MinerAPI.confirmChangeWorkerAddress(target);

        Errors.revertOnError(exit_code);
    }

    function get_peer_id(CommonTypes.FilActorId target) public view returns (CommonTypes.FilAddress memory) {
        (int256 exit_code, CommonTypes.FilAddress memory result) = MinerAPI.getPeerId(target);

        Errors.revertOnError(exit_code);

        return result;
    }

    function get_multiaddresses(CommonTypes.FilActorId target) public view returns (MinerTypes.GetMultiaddrsReturn memory) {
        (int256 exit_code, MinerTypes.GetMultiaddrsReturn memory result) = MinerAPI.getMultiaddresses(target);

        Errors.revertOnError(exit_code);

        return result;
    }

    function withdraw_balance(CommonTypes.FilActorId target, CommonTypes.BigInt memory amount) public returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = MinerAPI.withdrawBalance(target, amount);

        Errors.revertOnError(exit_code);

        return result;
    }
}
