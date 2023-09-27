// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {FilAddresses} from "contracts/v0.8/utils/FilAddresses.sol";
import {FilAddressIdConverter} from "contracts/v0.8/utils/FilAddressIdConverter.sol";
import {CommonTypes} from "contracts/v0.8/types/CommonTypes.sol";
import "forge-std/console.sol";

contract FilAddressesTest is Test {
    error InvalidAddress();

    function testFuzz_toEthAddressInvalidFirstByte(address addr, bytes1 firstByte) public {
        vm.assume(firstByte != hex"04");
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(abi.encodePacked(firstByte, hex"0a", addr));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress);
    }

    function testFuzz_toEthAddressInvalidSecondByte(address addr, bytes1 secondByte) public {
        vm.assume(secondByte != hex"0a");
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(abi.encodePacked(hex"04", secondByte, addr));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress);
    }

    function testFuzz_toEthAddressInvalidBytesLength(address addr, bytes1 endByte) public {
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(abi.encodePacked("040b", addr, endByte));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress);
    }

    function testFuzz_toEthAddress(address addr) public {
        bytes memory addrBytes = abi.encodePacked(addr);
        bytes memory filAddressBytes = abi.encodePacked(hex"040a", addrBytes);
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(filAddressBytes);

        address ethAddress = FilAddresses.toEthAddress(filAddress);

        assertEq(addr, ethAddress);
    }

    function testFuzz_fromEthAddress(address addr) public {
        bytes memory addrBytes = abi.encodePacked(addr);
        bytes memory filAddressBytes = abi.encodePacked(hex"040a", addrBytes);

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromEthAddress(addr);

        assertEq(filAddressBytes, filAddress.data);
    }

    function testFuzz_fromBytesFirstByte0x00(bytes memory data) public {
        vm.assume(data.length > 0 && data.length <= 10);
        data[0] = 0x00;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesFirstByte0x00InvalidLength(bytes memory data) public {
        vm.assume(data.length > 10);
        data[0] = 0x00;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesFirstByte0x01(bytes memory data) public {
        vm.assume(data.length == 21);
        data[0] = 0x01;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesFirstByte0x01InvalidLength(bytes memory data) public {
        vm.assume(data.length > 0 && data.length != 21);
        data[0] = 0x01;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesFirstByte0x02(bytes memory data) public {
        vm.assume(data.length == 21);
        data[0] = 0x02;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesFirstByte0x02InvalidLength(bytes memory data) public {
        vm.assume(data.length > 0 && data.length != 21);
        data[0] = 0x02;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesFirstByte0x03(bytes memory data) public {
        vm.assume(data.length == 49);
        data[0] = 0x03;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesFirstByte0x03InvalidLength(bytes memory data) public {
        vm.assume(data.length > 0 && data.length != 49);
        data[0] = 0x03;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesFirstByte0x04(bytes memory data) public {
        vm.assume(data.length > 0 && data.length <= 64);
        data[0] = 0x04;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesFirstByte0x04InvalidLength(bytes memory data) public {
        vm.assume(data.length > 64);
        data[0] = 0x04;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesFirstByteOtherInvalid(bytes memory data) public {
        vm.assume(data.length > 0 && data.length <= 256 && data[0] > 0x04);

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFromActorId(uint64 actorId) public {
        vm.assume(actorId > 0 && actorId < 50);
        // conversion to uint16 needed to get actorId in two bytes
        bytes memory actorIdBytes = abi.encodePacked(uint16(actorId));
        CommonTypes.FilAddress memory filAddress = FilAddresses.fromActorID(actorId);
        assertEq(filAddress.data, actorIdBytes);
    }
}
