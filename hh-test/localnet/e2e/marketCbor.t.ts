import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("Market Cbot Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (MarketCBORTest)`)

    const marketCBOR_SC = await utils.deployContract(deployer, "MarketCBORTest")

    //note: additional checks performed inside contracts (all revert on error)
    await marketCBOR_SC.eth.contract.testDealProposalSerDes()
    await utils.defaultTxDelay()
}
