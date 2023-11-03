// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {CommonTypes} from "contracts/v0.8/types/CommonTypes.sol";
import {TypeConstructor} from "contracts/v0.8/utils/TypeConstructor.sol";

contract TypeConstructorTest is Test {
    error InvalidLength();

    // UNIT TESTS
    function test_dealLabelFromBytes() external {
        bytes memory data = bytes("test");

        CommonTypes.DealLabel memory label = TypeConstructor.dealLabelFromBytes(data);

        assertEq(label.data, data);
        assertEq(label.isString, false);
    }

    function test_dealLabelFromBytesInvalidInput() external {
        bytes memory data = new bytes(257);

        vm.expectRevert(InvalidLength.selector);
        TypeConstructor.dealLabelFromBytes(data);
    }

    function test_dealLabelFromString() external {
        string memory data = "test";

        CommonTypes.DealLabel memory label = TypeConstructor.dealLabelFromString(data);

        assertEq(label.data, bytes(data));
        assertEq(label.isString, true);
    }

    function test_dealLabelFromStringInvalidInput() external {
        string memory data = new string(257);

        vm.expectRevert(InvalidLength.selector);
        TypeConstructor.dealLabelFromString(data);
    }
    
    // FUZZING TESTS
    function testFuzz_dealLabelFromBytes(bytes memory data) external {
        vm.assume(data.length <= 256);

        CommonTypes.DealLabel memory label = TypeConstructor.dealLabelFromBytes(data);

        assertEq(label.data, data);
        assertEq(label.isString, false);
    }

    function testFuzz_dealLabelFromBytesInvalidLength(uint256 length) external {
        vm.assume(length > 256 && length < 33554177);

        bytes memory data = new bytes(length);

        vm.expectRevert(InvalidLength.selector);
        TypeConstructor.dealLabelFromBytes(data);
    }

    function testFuzz_dealLabelFromString(string memory data) external {
        vm.assume(bytes(data).length <= 256);

        CommonTypes.DealLabel memory label = TypeConstructor.dealLabelFromString(data);

        assertEq(label.data, bytes(data));
        assertEq(label.isString, true);
    }

    function testFuzz_dealLabelFromStringInvalidLength(uint256 length) external {
        vm.assume(length > 256 && length < 33554177);

        string memory data = new string(length);

        vm.expectRevert(InvalidLength.selector);
        TypeConstructor.dealLabelFromString(data);
    }
}
