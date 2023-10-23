// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../market.test.sol";

/// @notice This file is meant to serve as an example of an upgradeable contract for the market actor API.
/// @author MVP Workshop
contract MarketApiUUPSUpgradeableV2Test is MarketApiTest, Initializable, UUPSUpgradeable {
    uint dummyVar;

    function initialize() public initializer {
        dummyVar = 13;
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override {}
}
