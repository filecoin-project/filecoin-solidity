import { ethers, upgrades, network } from "hardhat"
import { expect } from "chai"

import * as utils from "../../utils"

import { MarketTypes, CommonTypes } from "../../../typechain-types/contracts/v0.8/tests/market.test.sol/MarketApiTest"

describe.only("Market Tests (Beacon)", () => {
    const DBG_TESTS = {}
    let currentTestName: string
    let market, beacon, deployer

    before(async () => {
        utils.removeProxyArtifacts()
    })

    beforeEach(function () {
        currentTestName = this.currentTest.title
        DBG_TESTS[currentTestName] = true
    })

    it("Test 1: Basic upgrade", async () => {
        const { deployer: _deployer } = await utils.performGeneralSetupOnCalibnet()
        deployer = _deployer

        const MarketContractFactory = (await ethers.getContractFactory("MarketApiUpgradeableTest", deployer.eth.signer)) as any

        beacon = await upgrades.deployBeacon(MarketContractFactory)
        await utils.defaultTxDelay()

        const instance = await upgrades.deployBeaconProxy(beacon, MarketContractFactory, [])
        await utils.defaultTxDelay()

        market = { eth: { contract: instance, address: await instance.getAddress() }, fil: { address: "" } }
        market.fil = { address: utils.ethAddressToFilAddress(market.eth.address) }

        await _upgradeProxy({ market, beacon, deployer })

        await utils.defaultTxDelay(2)
    })

    afterEach(() => {
        if (DBG_TESTS[currentTestName]) {
            utils.printDbgLog(currentTestName)
        }
    })
})

let proxyUpgraded = false
const _upgradeProxy = async ({ market, beacon, deployer }) => {
    if (proxyUpgraded) return

    const MarketContractFactoryV2 = (await ethers.getContractFactory("MarketApiUpgradeableV2Test", deployer.eth.signer)) as any
    await upgrades.upgradeBeacon(beacon, MarketContractFactoryV2)
    await utils.defaultTxDelay()

    market.eth.contract = MarketContractFactoryV2.attach(market.eth.address)

    proxyUpgraded = true
}
