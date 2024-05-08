import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"
import { CommonTypes, PowerTypes } from "../../../typechain-types/contracts/v0.8/tests/power.test.sol/PowerApiTest"

describe("Power Test", () => {
    const DBG_TESTS = {}
    let currentTestName: string

    before(async () => {})

    beforeEach(function () {
        currentTestName = this.currentTest.title
        DBG_TESTS[currentTestName] = true
    })

    it("Test 1: Integration test port", async () => {
        await test1(currentTestName)
        DBG_TESTS[currentTestName] = false
    })

    afterEach(() => {
        if (DBG_TESTS[currentTestName]) {
            utils.printDbgLog(currentTestName)
        }
    })
})
const test1 = async (testName: string) => {
    const dbg = utils.initDbg(testName)

    const { deployer, storageProvider } = await utils.performGeneralSetup()

    dbg(`Deploying contracts... (PowerApiTest)`)

    const powerSC = await utils.deployContract(deployer, "PowerApiTest")

    const expectedMinerCount = BigInt(1)
    const actualMinerCount = await powerSC.eth.contract.miner_count()

    expect(actualMinerCount).to.eq(expectedMinerCount)

    const expectedNetworkRawPower: CommonTypes.BigIntStruct = { val: "0x1000", neg: false }
    const actualNetworkRawPower = await powerSC.eth.contract.network_raw_power()

    expect(actualNetworkRawPower.neg).to.eq(expectedNetworkRawPower.neg)
    expect(actualNetworkRawPower.val).to.eq(expectedNetworkRawPower.val)

    const minerId = storageProvider.fil.id
    const expectedMinerRawPower: CommonTypes.BigIntStruct = { val: "0x1000", neg: false }
    const actualMinerRawPower: PowerTypes.MinerRawPowerReturnStruct = await powerSC.eth.contract.miner_raw_power(minerId)

    expect(actualMinerRawPower.raw_byte_power.neg).to.eq(expectedMinerRawPower.neg)
    expect(actualMinerRawPower.raw_byte_power.val).to.eq(expectedMinerRawPower.val)

    const expectedMinerConsensusCount = BigInt(1)
    const actualMinerConsensusCount = await powerSC.eth.contract.miner_consensus_count()

    expect(actualMinerConsensusCount).to.eq(expectedMinerConsensusCount)
}
