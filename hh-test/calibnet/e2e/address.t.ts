import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("Address Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer } = await utils.performGeneralSetupOnCalibnet()

    console.log(`Deploying contracts... (AddressTest)`)

    const addressSC = await utils.deployContract(deployer, "AddressTest")

    //note: no additional checks performed (reverts on error)
    await addressSC.eth.contract.actorid_conversion()
    await utils.defaultTxDelay()
}
