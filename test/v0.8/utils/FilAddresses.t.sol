// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {FilAddresses} from "contracts/v0.8/utils/FilAddresses.sol";
import {CommonTypes} from "contracts/v0.8/types/CommonTypes.sol";

contract FilAddressesTest is Test {
    error InvalidAddress();

    address internal testAddress = vm.addr(0x7);
    bytes internal testAddressBytes = abi.encodePacked(testAddress);
    CommonTypes.FilAddress internal testFilAddress = CommonTypes.FilAddress(
      abi.encodePacked(hex"040a", testAddress)
    );

    function testFromEthAddressValid() public {
        CommonTypes.FilAddress memory filAddress = FilAddresses.fromEthAddress(testAddress);
        bytes memory filAddressBytes = abi.encodePacked(hex"040a", testAddressBytes);
        assertEq(filAddressBytes, filAddress.data);
    }

    function testToEthAddressValid() public {
        bytes memory data = testFilAddress.data;
        address addr = FilAddresses.toEthAddress(data);
        assertEq(testAddress, addr);
    }

    function testToEthAddressValidInvalidFirstByte() public {
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(
          abi.encodePacked(hex"030a", testAddress)
        );

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress.data);
    }

    function testToEthAddressValidInvalidSecondByte() public {
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(
          abi.encodePacked(hex"040b", testAddress)
        );

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress.data);
    }

    function testToEthAddressValidInvalidBytesLength() public {
        CommonTypes.FilAddress memory filAddress = CommonTypes.FilAddress(
          abi.encodePacked(hex"040b", testAddress, hex"00")
        );

        vm.expectRevert(InvalidAddress.selector);
        FilAddresses.toEthAddress(filAddress.data);
    }

    function testFuzz_fromEthAddress(address addr) public {
        bytes memory addrBytes = abi.encodePacked(addr);
        bytes memory filAddressBytes = abi.encodePacked(hex"040a", addrBytes);

        CommonTypes.FilAddress memory filAddress = FilAddresses.fromEthAddress(addr);

        assertEq(filAddressBytes, filAddress.data);
    }

    function testFuzz_toEthAddress(address addr) public {
        bytes memory addrBytes = abi.encodePacked(addr);
        bytes memory filAddressBytes = abi.encodePacked(hex"040a", addrBytes);

        address ethAddress = FilAddresses.toEthAddress(filAddressBytes);

        assertEq(addr, ethAddress);
    }
}
