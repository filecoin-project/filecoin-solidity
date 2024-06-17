import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("Leb128 Test", () => {
    const DBG_TESTS = {}
    let currentTestName: string

    before(async () => {})

    beforeEach(function () {
        currentTestName = this.currentTest.title
        DBG_TESTS[currentTestName] = true
    })

    it("Test 1: Integration test port", async () => {
        // await test1(currentTestName)
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
    const { deployer } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (Leb128Generated[1..15]Test)`)
    const leb128_SC = []
    for (let i = 1; i < 15; ++i) {
        const cName = `Leb128Generated${i}Test`
        const sc = await utils.deployContract(deployer, cName)
        leb128_SC.push(sc)
    }

    for (const l128_SC of leb128_SC) {
        //note: additional checks performed inside contracts (all revert on error)
        await l128_SC.eth.contract.unsiged_integer_leb128_encoding_generated()
    }
}
