import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("Market Cbot Test", () => {
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

    dbg(`Deploying contracts... (MarketCBORTest)`)

    const marketCBOR_SC = await utils.deployContract(deployer, "MarketCBORTest")

    //note: additional checks performed inside contracts (all revert on error)
    await marketCBOR_SC.eth.contract.testDealProposalSerDes()
    await utils.defaultTxDelay()
}
