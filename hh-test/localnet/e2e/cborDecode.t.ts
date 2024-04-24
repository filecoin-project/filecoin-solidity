import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

describe("CborDecode Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (CborDecodeTest)`)

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
