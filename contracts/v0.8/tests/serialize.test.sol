// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {FilAddresses} from "contracts/v0.8/utils/FilAddresses.sol";
import {FilAddressIdConverter} from "contracts/v0.8/utils/FilAddressIdConverter.sol";
import {CommonTypes} from "contracts/v0.8/types/CommonTypes.sol";

import "../cbor/FilecoinCbor.sol";

contract FilAddressSerialize is Test {
    using FilecoinCBOR for *;

    function test_1() external {
        CommonTypes.FilAddress memory addr1 = CommonTypes.FilAddress({data: abi.encodePacked([uint8(0), 0x04, 0x22])});
        //0x5860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000022
        CommonTypes.FilAddress memory addr2 = CommonTypes.FilAddress({data: abi.encode([0x66])});
        //0x584000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066
        assertEq(addr2.serializeAddress(), abi.encodePacked([uint8(0), 0x04, 0x22]));
    }
}
