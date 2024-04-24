import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("Leb128 Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
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
        await utils.defaultTxDelay()
    }
}
