import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"
import { CommonTypes } from "../../../typechain-types/contracts/v0.8/tests/send.test.sol/SendApiTest"

describe("Send Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (SendApiTest)`)

    const sendSC = await utils.deployContract(deployer, "SendApiTest")

    //send some tokens to the smart contract
    await deployer.eth.signer.sendTransaction(
        {
            to: sendSC.eth.address,
            value: 100,
        },
        { gasLimit: 100000000 }
    )
    await utils.defaultTxDelay()

    //note: additional checks performed inside contracts (all revert on error)
    //calling `send`
    console.log("calling `send`")
    // console.log(sendSC.eth.contract, sendSC.eth.contract.interface, sendSC.eth.contract.interface.fragments)
    const target = 0x65
    const amount = 10
    await sendSC.eth.contract.send_with_actor_id(target, amount)
    await utils.defaultTxDelay()

    //calling `send (address)`
    console.log("calling `send (address)`")
    const target2: CommonTypes.FilAddressStruct = {
        data: Uint8Array.from([0x00, 0x65]),
    }
    const amount2 = 10
    await sendSC.eth.contract.send_with_address(target2, amount2)
    await utils.defaultTxDelay()
}
