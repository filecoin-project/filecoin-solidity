// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {CommonTypes} from "contracts/v0.8/types/CommonTypes.sol";
import {TypeConstructor} from "contracts/v0.8/utils/TypeConstructor.sol";

contract TypeConstructorTest is Test {
    uint constant MAX_INVALID_DEAL_LABEL_LENGTH = 33554177; // test environment limit

    error InvalidLength();

    // UNIT TESTS
    function test_dealLabelFromBytes() external {
        bytes memory data =
            hex"6d41584367354149676d744a71377968314a5473474a6b50724131684c61536e585a49452b4d66656550316254384f4f47623441";

        CommonTypes.DealLabel memory label = TypeConstructor.dealLabelFromBytes(data);

        assertEq(label.data, data);
        assertEq(label.isString, false);
    }

    function test_dealLabelFromBytesInvalidInput() external {
        bytes memory data = new bytes(CommonTypes.MAX_DEAL_LABEL_LENGTH + 1);

        vm.expectRevert(InvalidLength.selector);
        TypeConstructor.dealLabelFromBytes(data);
    }

    function test_dealLabelFromString() external {
        string memory data = "mAXCg5AIg8YBXbFjtdBy1iZjpDYAwRSt0elGLF5GvTqulEii1VcM";
        bytes memory expectedValue =
            hex"6d41584367354149673859425862466a7464427931695a6a704459417752537430656c474c463547765471756c4569693156634d";

        CommonTypes.DealLabel memory label = TypeConstructor.dealLabelFromString(data);

        assertEq(label.data, expectedValue);
        assertEq(label.isString, true);
    }

    function test_dealLabelFromStringInvalidInput() external {
        string memory data = new string(CommonTypes.MAX_DEAL_LABEL_LENGTH + 1);

        vm.expectRevert(InvalidLength.selector);
        TypeConstructor.dealLabelFromString(data);
    }

    // FUZZING TESTS
    function testFuzz_dealLabelFromBytes(bytes memory data) external {
        vm.assume(data.length <= CommonTypes.MAX_DEAL_LABEL_LENGTH);

        CommonTypes.DealLabel memory label = TypeConstructor.dealLabelFromBytes(data);

        assertEq(label.data, data);
        assertEq(label.isString, false);
    }

    function testFuzz_dealLabelFromBytesInvalidLength(uint256 length) external {
        vm.assume(length > CommonTypes.MAX_DEAL_LABEL_LENGTH && length < MAX_INVALID_DEAL_LABEL_LENGTH);

        bytes memory data = new bytes(length);

        vm.expectRevert(InvalidLength.selector);
        TypeConstructor.dealLabelFromBytes(data);
    }

    function testFuzz_dealLabelFromString(string memory data) external {
        vm.assume(bytes(data).length <= CommonTypes.MAX_DEAL_LABEL_LENGTH);

        CommonTypes.DealLabel memory label = TypeConstructor.dealLabelFromString(data);

        assertEq(label.data, bytes(data));
        assertEq(label.isString, true);
    }

    function testFuzz_dealLabelFromStringInvalidLength(uint256 length) external {
        vm.assume(length > CommonTypes.MAX_DEAL_LABEL_LENGTH && length < MAX_INVALID_DEAL_LABEL_LENGTH);

        string memory data = new string(length);

        vm.expectRevert(InvalidLength.selector);
        TypeConstructor.dealLabelFromString(data);
    }
}
