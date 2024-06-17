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

import "./types/MinerTypes.sol";
import "./types/CommonTypes.sol";
import "./cbor/MinerCbor.sol";
import "./cbor/FilecoinCbor.sol";
import "./cbor/BytesCbor.sol";
import "./utils/Misc.sol";
import "./utils/Actor.sol";

/// @title This library is a proxy to a built-in Miner actor. Calling one of its methods will result in a cross-actor call being performed.
/// @notice During miner initialization, a miner actor is created on the chain, and this actor gives the miner its ID f0.... The miner actor is in charge of collecting all the payments sent to the miner.
/// @dev For more info about the miner actor, please refer to https://lotus.filecoin.io/storage-providers/operate/addresses/
/// @author Zondax AG
library MinerAPI {
    using MinerCBOR for *;
    using FilecoinCBOR for *;
    using BytesCBOR for bytes;

    /// @notice Income and returned collateral are paid to this address
    /// @notice This address is also allowed to change the worker address for the miner
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the owner address of a Miner
    function getOwner(CommonTypes.FilActorId target) internal view returns (int256, MinerTypes.GetOwnerReturn memory) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByIDReadOnly(target, MinerTypes.GetOwnerMethodNum, Misc.NONE_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeGetOwnerReturn());
        }

        return (exit_code, MinerTypes.GetOwnerReturn({owner: CommonTypes.FilAddress({data: hex""}), proposed: CommonTypes.FilAddress({data: hex""})}));
    }

    /// @notice Proposes or confirms a change of owner address.
    /// @notice If invoked by the current owner, proposes a new owner address for confirmation. If the proposed address is the current owner address, revokes any existing proposal that proposed address.
    /// @param target  The miner actor id you want to interact with
    /// @param addr New owner address
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function changeOwnerAddress(CommonTypes.FilActorId target, CommonTypes.FilAddress memory addr) internal returns (int256) {
        bytes memory raw_request = addr.serializeAddress();

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByID(
            target,
            MinerTypes.ChangeOwnerAddressMethodNum,
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

    /// @notice Returns information whether an address is miner's controlling address
    /// @param target  The miner actor id you want to interact with
    /// @param addr The "controlling" addresses are the Owner, the Worker, and all Control Addresses.
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return Whether the provided address is "controlling".
    function isControllingAddress(CommonTypes.FilActorId target, CommonTypes.FilAddress memory addr) internal view returns (int256, bool) {
        bytes memory raw_request = addr.serializeAddress();

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByIDReadOnly(
            target,
            MinerTypes.IsControllingAddressMethodNum,
            Misc.CBOR_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeBool());
        }

        return (exit_code, false);
    }

    /// @dev For more information about sector sizes, please refer to https://spec.filecoin.io/systems/filecoin_mining/sector/#section-systems.filecoin_mining.sector
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the miner's sector size.
    function getSectorSize(CommonTypes.FilActorId target) internal view returns (int256, uint64) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByIDReadOnly(target, MinerTypes.GetSectorSizeMethodNum, Misc.NONE_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeUint64());
        }

        return (exit_code, uint64(0));
    }

    /// @notice This is calculated as actor balance - (vesting funds + pre-commit deposit + initial pledge requirement + fee debt)
    /// @notice Can go negative if the miner is in IP debt.
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the available balance of this miner.
    function getAvailableBalance(CommonTypes.FilActorId target) internal view returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByIDReadOnly(
            target,
            MinerTypes.GetAvailableBalanceMethodNum,
            Misc.NONE_CODEC,
            raw_request
        );

        if (exit_code == 0) {
            return (0, result.deserializeBytesBigInt());
        }

        return (exit_code, CommonTypes.BigInt({val: hex"00", neg: false}));
    }

    /// @notice Returns specified miner's vesting funds
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return the funds vesting in this miner as a list of (vesting_epoch, vesting_amount) tuples.
    function getVestingFunds(CommonTypes.FilActorId target) internal view returns (int256, MinerTypes.VestingFunds[] memory) {
        bytes memory raw_request = new bytes(0);
        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByIDReadOnly(target, MinerTypes.GetVestingFundsMethodNum, Misc.NONE_CODEC, raw_request);
        if (exit_code == 0) {
            return (0, result.deserializeGetVestingFundsReturn());
        }
        return (exit_code, new MinerTypes.VestingFunds[](0));
    }

    /// @notice Proposes or confirms a change of beneficiary address.
    /// @notice A proposal must be submitted by the owner, and takes effect after approval of both the proposed beneficiary and current beneficiary, if applicable, any current beneficiary that has time and quota remaining.
    /// @notice See FIP-0029, https://github.com/filecoin-project/FIPs/blob/master/FIPS/fip-0029.md
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function changeBeneficiary(CommonTypes.FilActorId target, MinerTypes.ChangeBeneficiaryParams memory params) internal returns (int256) {
        bytes memory raw_request = params.serializeChangeBeneficiaryParams();

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByID(
            target,
            MinerTypes.ChangeBeneficiaryMethodNum,
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

    /// @notice This method is for use by other actors (such as those acting as beneficiaries), and to abstract the state representation for clients.
    /// @notice Retrieves the currently active and proposed beneficiary information.
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function getBeneficiary(CommonTypes.FilActorId target) internal view returns (int256, MinerTypes.GetBeneficiaryReturn memory) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByIDReadOnly(target, MinerTypes.GetBeneficiaryMethodNum, Misc.NONE_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeGetBeneficiaryReturn());
        }

        MinerTypes.GetBeneficiaryReturn memory empty_res;
        return (exit_code, empty_res);
    }

    /// @notice Change's a miner's worker address
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function changeWorkerAddress(CommonTypes.FilActorId target, MinerTypes.ChangeWorkerAddressParams memory params) internal returns (int256) {
        bytes memory raw_request = params.serializeChangeWorkerAddressParams();

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByID(
            target,
            MinerTypes.ChangeWorkerAddressMethodNum,
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

    /// @notice Change's a miner's peer id
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function changePeerId(CommonTypes.FilActorId target, CommonTypes.FilAddress memory newId) internal returns (int256) {
        bytes memory raw_request = newId.serializeArrayFilAddress();

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByID(target, MinerTypes.ChangePeerIDMethodNum, Misc.CBOR_CODEC, raw_request, 0, false);
        if (result.length != 0) {
            revert Actor.InvalidResponseLength();
        }

        return exit_code;
    }

    /// @notice Changes multiaddresses associated with a miner
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function changeMultiaddresses(CommonTypes.FilActorId target, CommonTypes.FilAddress[] memory new_multi_addrs) internal returns (int256) {
        bytes memory raw_request = new_multi_addrs.serializeChangeMultiaddrsParams();

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByID(
            target,
            MinerTypes.ChangeMultiaddrsMethodNum,
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

    /// @notice Repays miner's debt
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function repayDebt(CommonTypes.FilActorId target) internal returns (int256) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByID(target, MinerTypes.RepayDebtMethodNum, Misc.NONE_CODEC, raw_request, 0, false);
        if (result.length != 0) {
            revert Actor.InvalidResponseLength();
        }

        return exit_code;
    }

    /// @notice Changing a miner's worker address is a two step process
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    function confirmChangeWorkerAddress(CommonTypes.FilActorId target) internal returns (int256) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByID(
            target,
            MinerTypes.ConfirmChangeWorkerAddressMethodNum,
            Misc.NONE_CODEC,
            raw_request,
            0,
            false
        );
        if (result.length != 0) {
            revert Actor.InvalidResponseLength();
        }

        return exit_code;
    }

    /// @notice Returns miner's peer id
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return peer id for `target`
    function getPeerId(CommonTypes.FilActorId target) internal view returns (int256, CommonTypes.FilAddress memory) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByIDReadOnly(target, MinerTypes.GetPeerIDMethodNum, Misc.NONE_CODEC, raw_request);

        if (exit_code == 0) {
            return (0, result.deserializeArrayFilAddress());
        }

        return (exit_code, CommonTypes.FilAddress({data: hex""}));
    }

    /// @notice Returns miner's multiaddresses
    /// @param target The miner actor id you want to interact with
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return multiaddresses for `target`
    function getMultiaddresses(CommonTypes.FilActorId target) internal view returns (int256, CommonTypes.FilAddress[] memory) {
        bytes memory raw_request = new bytes(0);

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByIDReadOnly(target, MinerTypes.GetMultiaddrsMethodNum, Misc.NONE_CODEC, raw_request);
        if (exit_code == 0) {
            return (0, result.deserializeGetMultiaddrsReturn());
        }

        return (exit_code, new CommonTypes.FilAddress[](0));
    }

    /// @notice Withdraws balance for a specified miner
    /// @param target The miner actor id you want to interact with
    /// @param amount the amount you want to withdraw
    /// @return exit code (!= 0) if an error occured, 0 otherwise
    /// @return new balance for `target`
    function withdrawBalance(CommonTypes.FilActorId target, CommonTypes.BigInt memory amount) internal returns (int256, CommonTypes.BigInt memory) {
        bytes memory raw_request = amount.serializeArrayBigInt();

        (int256 exit_code, bytes memory result) = Actor.callNonSingletonByID(
            target,
            MinerTypes.WithdrawBalanceMethodNum,
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
}
