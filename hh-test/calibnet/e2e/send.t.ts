import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"
import { CommonTypes } from "../../../typechain-types/contracts/v0.8/tests/send.test.sol/SendApiTest"

describe("Send Test", () => {
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

    dbg(`Deploying contracts... (SendApiTest)`)

    const sendSC = await utils.deployContract(deployer, "SendApiTest")

    //send some tokens to the smart contract
    await deployer.eth.signer.sendTransaction({
        to: sendSC.eth.address,
        value: 100,
    })
    await utils.defaultTxDelay()

    //note: additional checks performed inside contracts (all revert on error)
    //calling `send`
    dbg("calling `send`")
    const target = 0x65
    const amount = 10
    await sendSC.eth.contract.send_with_actor_id(target, amount)
    await utils.defaultTxDelay()

    //calling `send (address)`
    dbg("calling `send (address)`")
    const target2: CommonTypes.FilAddressStruct = {
        data: Uint8Array.from([0x00, 0x65]),
    }
    const amount2 = 10
    await sendSC.eth.contract.send_with_address(target2, amount2)
    await utils.defaultTxDelay()
}
