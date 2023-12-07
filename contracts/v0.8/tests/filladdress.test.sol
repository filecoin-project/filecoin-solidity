// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {FilAddresses} from "contracts/v0.8/utils/FilAddresses.sol";
import {FilAddressIdConverter} from "contracts/v0.8/utils/FilAddressIdConverter.sol";
import {CommonTypes} from "contracts/v0.8/types/CommonTypes.sol";

contract FilAddressesTest is Test {
    address testAddress = makeAddr("testaddress");
    bytes2 constant DELEGATED_EAM_ADDRESS_PREFIX = hex"040a";

    error InvalidAddress();

    // UNIT TESTS
    function test_fromEthAddress() external {
        bytes memory filAddress = FilAddresses.fromEthAddress(testAddress).data;
        assertEq(filAddress, abi.encodePacked(DELEGATED_EAM_ADDRESS_PREFIX, testAddress));
    }

    function test_toEthAddress() external {
        CommonTypes.FilAddress memory filAddress =
            CommonTypes.FilAddress(abi.encodePacked(DELEGATED_EAM_ADDRESS_PREFIX, testAddress));
        address ethAddress = FilAddresses.toEthAddress(filAddress);
        assertEq(testAddress, ethAddress);
    }

    function test_toEthAddressInvalidFirstByte() external {
        CommonTypes.FilAddress memory invalidFilAddress =
            CommonTypes.FilAddress(abi.encodePacked(hex"00", CommonTypes.EAM_ID, testAddress));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(invalidFilAddress);
    }

    function test_toEthAddressInvalidSecondByte() external {
        CommonTypes.FilAddress memory invalidFilAddress =
            CommonTypes.FilAddress(abi.encodePacked(CommonTypes.PROTOCOL_DELEGATED, hex"00", testAddress));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(invalidFilAddress);
    }

    function test_toEthAddressInvalidLength() external {
        CommonTypes.FilAddress memory invalidFilAddress =
            CommonTypes.FilAddress(abi.encodePacked(DELEGATED_EAM_ADDRESS_PREFIX, testAddress, hex"00"));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(invalidFilAddress);
    }

    function test_fromActorID() external {
        CommonTypes.FilAddress memory result = FilAddresses.fromActorID(1000);
        assertEq(keccak256(result.data), keccak256(hex"00e807"));

        result = FilAddresses.fromActorID(type(uint64).max);
        assertEq(keccak256(result.data), keccak256(hex"00ffffffffffffffffff01"));
    }

    function test_fromBytes() external {
        CommonTypes.FilAddress memory result = FilAddresses.fromBytes(hex"000a");
        assertEq(keccak256(result.data), keccak256(hex"000a"));

        result = FilAddresses.fromBytes(hex"00ffffffffffffffffff01");
        assertEq(keccak256(result.data), keccak256(hex"00ffffffffffffffffff01"));

        result = FilAddresses.fromBytes(hex"01fd1d0f4dfcd7e99afcb99a8326b7dc459d32c628");
        assertEq(keccak256(result.data), keccak256(hex"01fd1d0f4dfcd7e99afcb99a8326b7dc459d32c628"));

        result = FilAddresses.fromBytes(hex"02e54dea4f9bc5b47d261819826d5e1fbf8bc5503b");
        assertEq(keccak256(result.data), keccak256(hex"02e54dea4f9bc5b47d261819826d5e1fbf8bc5503b"));

        result = FilAddresses.fromBytes(
            hex"03ad58df696e2d4e91ea86c881e938ba4ea81b395e12797b84b9cf314b9546705e839c7a99d606b247ddb4f9ac7a3414dd"
        );
        assertEq(
            keccak256(result.data),
            keccak256(
                hex"03ad58df696e2d4e91ea86c881e938ba4ea81b395e12797b84b9cf314b9546705e839c7a99d606b247ddb4f9ac7a3414dd"
            )
        );

        result = FilAddresses.fromBytes(hex"040a71C7656EC7ab88b098defB751B7401B5f6d8976F");
        assertEq(keccak256(result.data), keccak256(hex"040a71C7656EC7ab88b098defB751B7401B5f6d8976F"));
    }

    function test_fromBytesProtocolIDInvalidInputLengthShort() external {
        bytes memory invalidInput = hex"00";
        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(invalidInput);
    }

    function test_fromBytesProtocolIDInvalidInputLengthLong() external {
        bytes memory invalidInput =
            abi.encodePacked(CommonTypes.PROTOCOL_ID, new bytes(CommonTypes.MAX_PROTOCOL_ID_ADDRESS_LENGTH));
        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(invalidInput);
    }

    function test_fromBytesProtocolSECP256K1InvalidInput() external {
        bytes memory invalidInput = abi.encodePacked(
            CommonTypes.PROTOCOL_SECP256K1, new bytes(CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH)
        );
        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(invalidInput);
    }

    function test_fromBytesProtocolActorInvalidInput() external {
        bytes memory invalidInput =
            abi.encodePacked(CommonTypes.PROTOCOL_ACTOR, new bytes(CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH));
        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(invalidInput);
    }

    function test_fromBytesProtocolBLSInvalidInput() external {
        bytes memory invalidInput =
            abi.encodePacked(CommonTypes.PROTOCOL_BLS, new bytes(CommonTypes.PROTOCOL_BLS_ADDRESS_LENGTH));
        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(invalidInput);
    }

    function test_fromBytesProtocolDelegatedEAMInvalidInputLength() external {
        bytes memory invalidInput =
            abi.encodePacked(DELEGATED_EAM_ADDRESS_PREFIX, new bytes(CommonTypes.PROTOCOL_DELEGATED_EAM_ADDRESS_LENGTH));
        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(invalidInput);
    }

    function test_validate() external pure {
        CommonTypes.FilAddress memory inputAddress = CommonTypes.FilAddress(hex"0001");
        assert(FilAddresses.validate(inputAddress));

        inputAddress = FilAddresses.fromActorID(type(uint64).max);
        assert(FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(
                CommonTypes.PROTOCOL_SECP256K1, new bytes(CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH-1)
            )
        );
        assert(FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(
                CommonTypes.PROTOCOL_ACTOR, new bytes(CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH-1)
            )
        );
        assert(FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(CommonTypes.PROTOCOL_BLS, new bytes(CommonTypes.PROTOCOL_BLS_ADDRESS_LENGTH-1))
        );
        assert(FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(
                DELEGATED_EAM_ADDRESS_PREFIX, new bytes(CommonTypes.PROTOCOL_DELEGATED_EAM_ADDRESS_LENGTH-2)
            )
        );
        assert(FilAddresses.validate(inputAddress));
    }

    function test_validateInvalidInput() external pure {
        CommonTypes.FilAddress memory inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(CommonTypes.PROTOCOL_ID, new bytes(CommonTypes.MAX_PROTOCOL_ID_ADDRESS_LENGTH))
        );
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(abi.encodePacked(CommonTypes.PROTOCOL_ID));
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(
                CommonTypes.PROTOCOL_SECP256K1, new bytes(CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH)
            )
        );
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(CommonTypes.PROTOCOL_ACTOR, new bytes(CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH))
        );
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(CommonTypes.PROTOCOL_BLS, new bytes(CommonTypes.PROTOCOL_BLS_ADDRESS_LENGTH))
        );
        assert(!FilAddresses.validate(inputAddress));

        inputAddress = CommonTypes.FilAddress(
            abi.encodePacked(
                DELEGATED_EAM_ADDRESS_PREFIX, new bytes(CommonTypes.PROTOCOL_DELEGATED_EAM_ADDRESS_LENGTH)
            )
        );
        assert(!FilAddresses.validate(inputAddress));
    }

    // FUZZING TESTS
    function testFuzz_toEthAddressInvalidFirstByte(address addr, bytes1 firstByte) public {
        vm.assume(firstByte != CommonTypes.PROTOCOL_DELEGATED);
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(abi.encodePacked(firstByte, hex"0a", addr));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress);
    }

    function testFuzz_toEthAddressInvalidSecondByte(address addr, bytes1 secondByte) public {
        vm.assume(secondByte != CommonTypes.EAM_ID);
        CommonTypes.FilAddress memory filAddress =
            CommonTypes.FilAddress(abi.encodePacked(CommonTypes.PROTOCOL_DELEGATED, secondByte, addr));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress);
    }

    function testFuzz_toEthAddressInvalidBytesLength(address addr, bytes1 endByte) public {
        CommonTypes.FilAddress memory filAddress =
            CommonTypes.FilAddress(abi.encodePacked(DELEGATED_EAM_ADDRESS_PREFIX, addr, endByte));

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress);
    }

    function testFuzz_toEthAddress(address addr) public {
        bytes memory addrBytes = abi.encodePacked(addr);
        bytes memory filAddressBytes = abi.encodePacked(DELEGATED_EAM_ADDRESS_PREFIX, addrBytes);
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(filAddressBytes);

        address ethAddress = FilAddresses.toEthAddress(filAddress);

        assertEq(addr, ethAddress);
    }

    function testFuzz_fromEthAddress(address addr) public {
        bytes memory addrBytes = abi.encodePacked(addr);
        bytes memory filAddressBytes = abi.encodePacked(DELEGATED_EAM_ADDRESS_PREFIX, addrBytes);

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromEthAddress(addr);

        assertEq(filAddressBytes, filAddress.data);
    }

    function testFuzz_fromBytesProtocolID(bytes memory data) public {
        vm.assume(
            data.length > CommonTypes.MIN_PROTOCOL_ID_ADDRESS_LENGTH
                && data.length <= CommonTypes.MAX_PROTOCOL_ID_ADDRESS_LENGTH
        );
        data[0] = CommonTypes.PROTOCOL_ID;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesProtocolIDInvalidLength(bytes memory data) public {
        vm.assume(
            data.length > CommonTypes.MAX_PROTOCOL_ID_ADDRESS_LENGTH
                || data.length == CommonTypes.MIN_PROTOCOL_ID_ADDRESS_LENGTH
        );
        data[0] = CommonTypes.PROTOCOL_ID;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesProtocolSECP256K1(bytes memory data) public {
        vm.assume(data.length == CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH);
        data[0] = CommonTypes.PROTOCOL_SECP256K1;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesProtocolSECP256K1InvalidLength(bytes memory data) public {
        vm.assume(data.length > 0 && data.length != CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH);
        data[0] = CommonTypes.PROTOCOL_SECP256K1;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesProtocolActor(bytes memory data) public {
        vm.assume(data.length == CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH);
        data[0] = CommonTypes.PROTOCOL_ACTOR;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesProtocolActorInvalidLength(bytes memory data) public {
        vm.assume(data.length > 0 && data.length != CommonTypes.PROTOCOL_SECP256K1_ACTOR_ADDRESS_LENGTH);
        data[0] = CommonTypes.PROTOCOL_ACTOR;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesProtocolBLS(bytes memory data) public {
        vm.assume(data.length == CommonTypes.PROTOCOL_BLS_ADDRESS_LENGTH);
        data[0] = CommonTypes.PROTOCOL_BLS;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesProtocolBLSInvalidLength(bytes memory data) public {
        vm.assume(data.length > 0 && data.length != CommonTypes.PROTOCOL_BLS_ADDRESS_LENGTH);
        data[0] = CommonTypes.PROTOCOL_BLS;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromBytesProtocolDelegatedEAM(bytes memory data) public {
        vm.assume(data.length == CommonTypes.PROTOCOL_DELEGATED_EAM_ADDRESS_LENGTH);
        data[0] = CommonTypes.PROTOCOL_DELEGATED;
        data[1] = CommonTypes.EAM_ID;

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromBytes(data);
        assertEq(data, filAddress.data);
    }

    function testFuzz_fromBytesProtocolDelegatedEAMInvalidLength(bytes memory data) public {
        vm.assume(data.length > 1 && data.length != CommonTypes.PROTOCOL_DELEGATED_EAM_ADDRESS_LENGTH);
        data[0] = CommonTypes.PROTOCOL_DELEGATED;
        data[1] = CommonTypes.EAM_ID;

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.fromBytes(data);
    }

    function testFuzz_fromActorId(uint64 actorId) public {
        vm.assume(actorId > 0 && actorId < 50);
        // conversion to uint16 needed to get actorId in two bytes
        bytes memory actorIdBytes = abi.encodePacked(uint16(actorId));
        CommonTypes.FilAddress memory filAddress = FilAddresses.fromActorID(actorId);
        assertEq(filAddress.data, actorIdBytes);
    }
}
