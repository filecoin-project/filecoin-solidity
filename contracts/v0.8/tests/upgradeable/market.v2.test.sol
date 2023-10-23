// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../market.test.sol";

/// @notice This file is meant to serve as an example of an upgradeable contract for the market actor API.
/// @author MVP Workshop
contract MarketApiUpgradeableV2Test is MarketApiTest, Initializable {
    uint dummyVar;

    function initialize() public initializer {
        dummyVar = 13;
    }
}
