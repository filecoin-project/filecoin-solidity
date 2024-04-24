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

import "../types/DataCapTypes.sol";
import "../types/CommonTypes.sol";
import "../cbor/BigIntCbor.sol";
import "../DataCapAPI.sol";
import "../utils/UtilsHandlers.sol";
import "../utils/Errors.sol";

/// @notice This file is meant to serve as a deployable contract of the datacap actor API, as the library by itself is not.
/// @notice It imports the library and create a callable method for each method in the library
/// @author Zondax AG
contract DataCapApiTest {
    address _n;
    address _n2;
    function dummy() public view returns (uint) {
        return 1301;
    }
    function name() public view returns (string memory) {
        (int256 exit_code, string memory result) = DataCapAPI.name();

        Errors.revertOnError(exit_code);

        return result;
    }

    function symbol() public view returns (string memory) {
        (int256 exit_code, string memory result) = DataCapAPI.symbol();

        Errors.revertOnError(exit_code);

        return result;
    }

    function total_supply() public view returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = DataCapAPI.totalSupply();

        Errors.revertOnError(exit_code);

        return result;
    }

    function balance(CommonTypes.FilAddress memory addr) public view returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = DataCapAPI.balance(addr);

        Errors.revertOnError(exit_code);

        return result;
    }

    function allowance(DataCapTypes.GetAllowanceParams memory params) public view returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = DataCapAPI.allowance(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function transfer(DataCapTypes.TransferParams memory params) public returns (DataCapTypes.TransferReturn memory) {
        (int256 exit_code, DataCapTypes.TransferReturn memory result) = DataCapAPI.transfer(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function transfer_from(DataCapTypes.TransferFromParams memory params) public returns (DataCapTypes.TransferFromReturn memory) {
        (int256 exit_code, DataCapTypes.TransferFromReturn memory result) = DataCapAPI.transferFrom(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function increase_allowance(DataCapTypes.IncreaseAllowanceParams memory params) public returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = DataCapAPI.increaseAllowance(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function decrease_allowance(DataCapTypes.DecreaseAllowanceParams memory params) public returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = DataCapAPI.decreaseAllowance(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function revoke_allowance(CommonTypes.FilAddress memory operator) public returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = DataCapAPI.revokeAllowance(operator);

        Errors.revertOnError(exit_code);

        return result;
    }

    function burn(CommonTypes.BigInt memory amount) public returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = DataCapAPI.burn(amount);

        Errors.revertOnError(exit_code);

        return result;
    }

    function burn_from(DataCapTypes.BurnFromParams memory params) public returns (DataCapTypes.BurnFromReturn memory) {
        (int256 exit_code, DataCapTypes.BurnFromReturn memory result) = DataCapAPI.burnFrom(params);

        Errors.revertOnError(exit_code);

        return result;
    }

    function handle_filecoin_method(uint64 method, uint64 codec, bytes calldata params) public pure {
        UtilsHandlers.handleFilecoinMethod(method, codec, params);
    }
}
