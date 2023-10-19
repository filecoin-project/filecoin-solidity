// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {FilAddresses} from "contracts/v0.8/utils/FilAddresses.sol";
import {FilAddressIdConverter} from "contracts/v0.8/utils/FilAddressIdConverter.sol";
import {CommonTypes} from "contracts/v0.8/types/CommonTypes.sol";
import "forge-std/console.sol";

contract FilAddressesTest is Test {
    address testAddress = makeAddr("testaddress");
    
    error InvalidAddress();

    // UNIT TESTS
    function test_fromEthAddress() external {
        bytes memory filAddress = FilAddresses.fromEthAddress(testAddress).data;
        assertEq(filAddress, abi.encodePacked(hex"040a", testAddress));
    }

    function test_toEthAddress() external {
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(abi.encodePacked(hex"040a", testAddress));
        address ethAddress = FilAddresses.toEthAddress(filAddress);
        assertEq(testAddress, ethAddress);
    }

    function test_toEthAddressWhenInputIsInvalid() external {
        CommonTypes.FilAddress memory invalidFilAddress = CommonTypes.FilAddress(abi.encodePacked(hex"000a", testAddress));

        vm.expectRevert(InvalidAddress.selector);
        address ethAddress = FilAddresses.toEthAddress(invalidFilAddress);

        invalidFilAddress = CommonTypes.FilAddress(abi.encodePacked(hex"0400", testAddress));

        vm.expectRevert(InvalidAddress.selector);
        ethAddress = FilAddresses.toEthAddress(invalidFilAddress);

        invalidFilAddress = CommonTypes.FilAddress(abi.encodePacked(hex"040a00", testAddress));

        vm.expectRevert(InvalidAddress.selector);
        ethAddress = FilAddresses.toEthAddress(invalidFilAddress);
    }

    function test_fromActorID() external {
        CommonTypes.FilAddress memory result = FilAddresses.fromActorID(1000);
        assertEq(keccak256(result.data), keccak256(hex"00e807"));
    }

    function test_fromBytes() external {
        CommonTypes.FilAddress memory result = FilAddresses.fromBytes(hex"000a");
        assertEq(keccak256(result.data), keccak256(hex"000a"));
    }

    function test_fromBytesWhenInputIsInvalid() external {
        bytes memory invalidInput = abi.encodePacked(hex"00", new bytes(10));
        vm.expectRevert(InvalidAddress.selector);
        CommonTypes.FilAddress memory result = FilAddresses.fromBytes(invalidInput);

        invalidInput = abi.encodePacked(hex"01", new bytes(21));
        vm.expectRevert(InvalidAddress.selector);
        result = FilAddresses.fromBytes(invalidInput);

        invalidInput = abi.encodePacked(hex"02", new bytes(21));
        vm.expectRevert(InvalidAddress.selector);
        result = FilAddresses.fromBytes(invalidInput);

        invalidInput = abi.encodePacked(hex"03", new bytes(49));
        vm.expectRevert(InvalidAddress.selector);
        result = FilAddresses.fromBytes(invalidInput);

        invalidInput = abi.encodePacked(hex"04", new bytes(64));
        vm.expectRevert(InvalidAddress.selector);
        result = FilAddresses.fromBytes(invalidInput);

        invalidInput = abi.encodePacked(hex"05", new bytes(64));
        vm.expectRevert(InvalidAddress.selector);
        result = FilAddresses.fromBytes(invalidInput);
    }

    function test_validate() external pure {
        CommonTypes.FilAddress memory inputAddress = CommonTypes.FilAddress(hex"00");
        assert(FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"01", new bytes(20)));
        assert(FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"02", new bytes(20)));
        assert(FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"03", new bytes(48)));
        assert(FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"04", new bytes(63)));
        assert(FilAddresses.validate(inputAddress));
    }

    function test_validateWhenInputIsInvalid() external pure {
        CommonTypes.FilAddress memory inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"00", new bytes(10)));
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"01", new bytes(19)));
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"02", new bytes(19)));
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"03", new bytes(47)));
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"04", new bytes(64)));
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(hex"05", new bytes(64)));
        assert(!FilAddresses.validate(inputAddress));
    }

    // FUZZING TESTS
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
