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

import "../types/PowerTypes.sol";
import "../types/CommonTypes.sol";
import "../PowerAPI.sol";
import "../utils/Errors.sol";

/// @notice This file is meant to serve as a deployable contract of the power actor API, as the library by itself is not.
/// @notice It imports the library and create a callable method for each method in the library
/// @author Zondax AG
contract PowerApiTest {
    function create_miner(PowerTypes.CreateMinerParams memory params, uint256 value) public payable returns (PowerTypes.CreateMinerReturn memory) {
        (int256 exit_code, PowerTypes.CreateMinerReturn memory result) = PowerAPI.createMiner(params, value);

        Errors.revertOnError(exit_code);

        return result;
    }

    function miner_count() public view returns (uint64) {
        (int256 exit_code, uint64 result) = PowerAPI.minerCount();

        Errors.revertOnError(exit_code);

        return result;
    }

    function miner_consensus_count() public view returns (int64) {
        (int256 exit_code, int64 result) = PowerAPI.minerConsensusCount();

        Errors.revertOnError(exit_code);

        return result;
    }

    function network_raw_power() public view returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = PowerAPI.networkRawPower();

        Errors.revertOnError(exit_code);

        return result;
    }

    function miner_raw_power(uint64 minerID) public view returns (PowerTypes.MinerRawPowerReturn memory) {
        (int256 exit_code, PowerTypes.MinerRawPowerReturn memory result) = PowerAPI.minerRawPower(minerID);

        Errors.revertOnError(exit_code);

        return result;
    }
}
