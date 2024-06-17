import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("BigInt Test", () => {
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

    dbg(`Deploying contracts... (BigIntsTest)`)

    const bigIntSC = await utils.deployContract(deployer, "BigIntsTest")

    //note: additional checks performed inside contracts (all revert on error)
    await bigIntSC.eth.contract.to_uint256()

    await bigIntSC.eth.contract.to_int256_negative()

    await bigIntSC.eth.contract.to_int256_positive()

    await bigIntSC.eth.contract.from_uint256()

    await bigIntSC.eth.contract.from_int256_positive()

    await bigIntSC.eth.contract.from_int256_negative()
}
