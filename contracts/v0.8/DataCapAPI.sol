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

import "./types/DataCapTypes.sol";
import "./types/CommonTypes.sol";
import "./cbor/FilecoinCbor.sol";
import "./cbor/DataCapCbor.sol";
import "./cbor/BytesCbor.sol";
import "./utils/Actor.sol";

/// @title This library is a proxy to the singleton DataCap actor (address: f0X). Calling one of its methods will result in a cross-actor call being performed.
/// @author Zondax AG
library DataCapAPI {
    using DataCapCBOR for *;
    using BytesCBOR for *;
    using FilecoinCBOR for *;

    /// @notice Return the name of DataCap token which is 'DataCap'.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return name of DataCap token
    function name() internal view returns (int256, string memory) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(DataCapTypes.ActorID, DataCapTypes.NameMethodNum, Misc.NONE_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeString());
        }

        return (exit_code, "");
    }

    /// @notice Return the symbol of DataCap token which is 'DCAP'.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return symbol of the DataCap token
    function symbol() internal view returns (int256, string memory) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(DataCapTypes.ActorID, DataCapTypes.SymbolMethodNum, Misc.NONE_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeString());
        }

        return (exit_code, "");
    }

    /// @notice Return the total supply of DataCap token.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return total supply of the DataCap token
    function totalSupply() internal view returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(DataCapTypes.ActorID, DataCapTypes.TotalSupplyMethodNum, Misc.NONE_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        return (exit_code, CommonTypes.BigInt({val: hex"00", neg: false}));
    }

    /// @notice Return the DataCap token balance for the wallet address.
    /// @param addr filecoin address for which to return the balance
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return DataCap token balance for the wallet address
    function balance(CommonTypes.FilAddress memory addr) internal view returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = addr.serializeAddress();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(DataCapTypes.ActorID, DataCapTypes.BalanceOfMethodNum, Misc.CBOR_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        return (exit_code, CommonTypes.BigInt({val: hex"00", neg: false}));
    }

    /// @notice Return the allowance between owner and operator address.
    /// @param params `owner` address and `operator` address
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return DataCap allowance between owner and operator address
    function allowance(DataCapTypes.GetAllowanceParams memory params) internal view returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = params.serializeGetAllowanceParams();

        (int256 exit_code, bytes memory result) = Actor.callByIDReadOnly(DataCapTypes.ActorID, DataCapTypes.AllowanceMethodNum, Misc.CBOR_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        return (exit_code, CommonTypes.BigInt({val: hex"00", neg: false}));
    }

    /// @notice Transfers data cap tokens to an address.
    /// @notice Data cap tokens are not generally transferable.
    /// @notice Succeeds if the to or from address is the governor, otherwise always fails.
    /// @param params `to` address, transfer `amount`, arbitary `operator_data`
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return new balances/allowances and associated receipient data
    function transfer(DataCapTypes.TransferParams memory params) internal returns (int256, DataCapTypes.TransferReturn memory) {
        bytes memory raw_request = params.serializeTransferParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(DataCapTypes.ActorID, DataCapTypes.TransferMethodNum, Misc.CBOR_CODEC, raw_request, 0, false);

        if (exit_code == 0) {
            return (0, result.deserializeTransferReturn());
        }

        DataCapTypes.TransferReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Transfers data cap tokens between addresses.
    /// @notice Data cap tokens are not generally transferable between addresses.
    /// @notice Succeeds if the to address is the governor, otherwise always fails.
    /// @param params `from` address, `to` address, transfer `amount`, and arbitary `operator_data`
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return new balances/allowances and associated receipient data
    function transferFrom(DataCapTypes.TransferFromParams memory params) internal returns (int256, DataCapTypes.TransferFromReturn memory) {
        bytes memory raw_request = params.serializeTransferFromParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            DataCapTypes.ActorID,
            DataCapTypes.TransferFromMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );

        if (exit_code == 0) {
            return (0, result.deserializeTransferFromReturn());
        }

        DataCapTypes.TransferFromReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Increase the DataCap token allowance that an operator can control of the owner's balance by the requested amount.
    /// @param params operator's address and the amount to be added to the current allowance
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return operator's new allowance for the provided owner
    function increaseAllowance(DataCapTypes.IncreaseAllowanceParams memory params) internal returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = params.serializeIncreaseAllowanceParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            DataCapTypes.ActorID,
            DataCapTypes.IncreaseAllowanceMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        return (exit_code, CommonTypes.BigInt({val: hex"00", neg: false}));
    }

    /// @notice Decrease the DataCap token allowance that an operator controls of the owner's balance by the requested amount.
    /// @param params operator's address and the amount to be substracted from the current allowance
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return operator's new allowance for the provided owner
    function decreaseAllowance(DataCapTypes.DecreaseAllowanceParams memory params) internal returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = params.serializeDecreaseAllowanceParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            DataCapTypes.ActorID,
            DataCapTypes.DecreaseAllowanceMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        return (exit_code, CommonTypes.BigInt({val: hex"00", neg: false}));
    }

    /// @notice Revoke the DataCap token allowance from the operator and set the operator's allowance in behave of owner/caller address to 0.
    /// @param operator address that will no longer have allowance for the owner/caller address
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return operator's new allowance for the provided owner
    function revokeAllowance(CommonTypes.FilAddress memory operator) internal returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = operator.serializeArrayFilAddress();

        (int256 exit_code, bytes memory result) = Actor.callByID(
            DataCapTypes.ActorID,
            DataCapTypes.RevokeAllowanceMethodNum,
            Misc.CBOR_CODEC,
            raw_request,
            0,
            false
        );

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        return (exit_code, CommonTypes.BigInt({val: hex"00", neg: false}));
    }

    /// @notice Burn an amount of DataCap token from the owner/caller address, decreasing total token supply.
    /// @param amount funds to be burned
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return owner's new allowance balance
    function burn(CommonTypes.BigInt memory amount) internal returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = amount.serializeArrayBigInt();

        (int256 exit_code, bytes memory result) = Actor.callByID(DataCapTypes.ActorID, DataCapTypes.BurnMethodNum, Misc.CBOR_CODEC, raw_request, 0, false);

        if (exit_code == 0) {
            return (0, result.deserializeArrayBigInt());
        }

        return (exit_code, CommonTypes.BigInt({val: hex"00", neg: false}));
    }

    /// @notice Burn an amount of DataCap token from the specified address (owner address), decrease the allowance of operator/caller, and decrease total token supply.
    /// @param params Owner address and amount
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return owner's new balance and its allowance fort operator/caller
    function burnFrom(DataCapTypes.BurnFromParams memory params) internal returns (int256, DataCapTypes.BurnFromReturn memory) {
        bytes memory raw_request = params.serializeBurnFromParams();

        (int256 exit_code, bytes memory result) = Actor.callByID(DataCapTypes.ActorID, DataCapTypes.BurnFromMethodNum, Misc.CBOR_CODEC, raw_request, 0, false);

        if (exit_code == 0) {
            return (0, result.deserializeBurnFromReturn());
        }

        return (
            exit_code,
            DataCapTypes.BurnFromReturn({balance: CommonTypes.BigInt({val: hex"00", neg: false}), allowance: CommonTypes.BigInt({val: hex"00", neg: false})})
        );
    }
}
