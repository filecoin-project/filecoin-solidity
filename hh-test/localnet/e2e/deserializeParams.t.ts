import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("Deserialize Params Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (DeserializeParamsTest)`)

    const deserializeParamsSC = await utils.deployContract(deployer, "DeserializeParamsTest")

    //note: additional checks performed inside contracts (all revert on error)
    await deserializeParamsSC.eth.contract.deserializeGetVestingFundsReturn()

    await utils.defaultTxDelay()
}
