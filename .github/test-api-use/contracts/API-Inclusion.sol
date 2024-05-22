// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;


import { FilAddresses } from  "filecoin-solidity-api/contracts/v0.8/utils/FilAddresses.sol";
import { CommonTypes } from "filecoin-solidity-api/contracts/v0.8/types/CommonTypes.sol";

import { AccountTypes } from "filecoin-solidity-api/contracts/v0.8/types/AccountTypes.sol";
import { DataCapTypes } from "filecoin-solidity-api/contracts/v0.8/types/DataCapTypes.sol";
import { MarketTypes } from "filecoin-solidity-api/contracts/v0.8/types/MarketTypes.sol";
import { MinerTypes } from "filecoin-solidity-api/contracts/v0.8/types/MinerTypes.sol";
import { PowerTypes } from "filecoin-solidity-api/contracts/v0.8/types/PowerTypes.sol";
import { VerifRegTypes } from "filecoin-solidity-api/contracts/v0.8/types/VerifRegTypes.sol";

import { AccountAPI } from "filecoin-solidity-api/contracts/v0.8/AccountAPI.sol";
import { DataCapAPI } from "filecoin-solidity-api/contracts/v0.8/DataCapAPI.sol";
import { MarketAPI } from "filecoin-solidity-api/contracts/v0.8/MarketAPI.sol";
import { MinerAPI } from "filecoin-solidity-api/contracts/v0.8/MinerAPI.sol";
import { PowerAPI } from "filecoin-solidity-api/contracts/v0.8/PowerAPI.sol";
import { PrecompilesAPI } from "filecoin-solidity-api/contracts/v0.8/PrecompilesAPI.sol";
import { SendAPI } from "filecoin-solidity-api/contracts/v0.8/SendAPI.sol";
import { VerifRegAPI } from "filecoin-solidity-api/contracts/v0.8/VerifRegAPI.sol";

contract API_Inclusion {
    
    //AccountAPI
    function account_authenticate_message(CommonTypes.FilActorId target, AccountTypes.AuthenticateMessageParams memory params) public view {
        AccountAPI.authenticateMessage(target, params);
    }

    //AddressAPI
     function actorid_conversion() public pure {
        uint64 actorID = 1;
        CommonTypes.FilAddress memory result = FilAddresses.fromActorID(actorID);
    }
    //DatacapAPI
    function bundle(DataCapTypes.TransferParams memory params) internal returns (int256, DataCapTypes.TransferReturn memory) {
        DataCapAPI.name();
        DataCapAPI.symbol();
    }

    //MarketAPI
    function withdraw_balance(MarketTypes.WithdrawBalanceParams memory params) public returns (CommonTypes.BigInt memory) {
        (int256 exit_code, CommonTypes.BigInt memory result) = MarketAPI.withdrawBalance(params);

        return result;
    }

    //MinerAPI
    function get_owner(CommonTypes.FilActorId target) external view returns (int256, MinerTypes.GetOwnerReturn memory) {
        MinerAPI.getOwner(target);
    }

    //PowerAPI
    function create_miner(PowerTypes.CreateMinerParams memory params, uint256 value) internal returns (int256, PowerTypes.CreateMinerReturn memory) {
        PowerAPI.createMiner(params, value);
    }

    //PrecompilesAPI
    function resolve_address(CommonTypes.FilAddress memory addr) internal view returns (uint64) {
        PrecompilesAPI.resolveAddress(addr);
    }

    //SendAPI
    function send(CommonTypes.FilAddress memory target, uint256 value) internal returns (int256) {
        SendAPI.send(target, value);
    }

    //VerifregAPI
  function remove_expired_claims(
        VerifRegTypes.RemoveExpiredClaimsParams memory params
    ) public returns (int256, VerifRegTypes.RemoveExpiredClaimsReturn memory) {
        VerifRegAPI.removeExpiredClaims(params);
    }
}
