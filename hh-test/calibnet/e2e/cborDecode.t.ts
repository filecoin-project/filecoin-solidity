import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("CborDecode Test", () => {
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

    const { deployer } = await utils.performGeneralSetupOnCalibnet()

    dbg(`Deploying contracts... (CborDecodeTest)`)

    const cborDecode = await utils.deployContract(deployer, "CborDecodeTest")

    //note: additional checks performed inside contracts (all revert on error)
    await cborDecode.eth.contract.decodeFixedArray()

    await cborDecode.eth.contract.decodeFalse()

    await cborDecode.eth.contract.decodeTrue()

    await cborDecode.eth.contract.decodeNull()

    await cborDecode.eth.contract.decodeInteger()

    await cborDecode.eth.contract.decodeString()

    await cborDecode.eth.contract.decodeStringWithWeirdChar()

    await cborDecode.eth.contract.decodeArrayU8()

    await utils.defaultTxDelay()
}
