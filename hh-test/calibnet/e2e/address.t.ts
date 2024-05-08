import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("Address Test", () => {
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

    dbg(`Deploying contracts... (AddressTest)`)

    const addressSC = await utils.deployContract(deployer, "AddressTest")

    //note: no additional checks performed (reverts on error)
    await addressSC.eth.contract.actorid_conversion()
    await utils.defaultTxDelay()
}
