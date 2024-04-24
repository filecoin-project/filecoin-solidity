import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("BigInt Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (BigIntsTest)`)

    const bigIntSC = await utils.deployContract(deployer, "BigIntsTest")

    //note: additional checks performed inside contracts (all revert on error)
    await bigIntSC.eth.contract.to_uint256()

    await bigIntSC.eth.contract.to_int256_negative()

    await bigIntSC.eth.contract.to_int256_positive()

    await bigIntSC.eth.contract.from_uint256()

    await bigIntSC.eth.contract.from_int256_positive()

    await bigIntSC.eth.contract.from_int256_negative()
}
