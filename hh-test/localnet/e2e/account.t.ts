import { ethers } from "hardhat"
import { expect, util } from "chai"

import { CommonTypes, AccountTypes } from "../../../typechain-types/contracts/v0.8/tests/account.test.sol/AccountApiTest"

import * as utils from "../../utils"

describe("Account Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer, client } = await utils.performGeneralSetup()

    const message =
        "8eabea2a4001061ac4c9fe3c517725b8829b159149a863b2a2320cc628d026a871d3cb34947371f384a9eb49ff9bd56a019fa70e10c06ac5ca93df3c1d6f54d540c57cbe2f5209cafdc12146d5d59172dd4d8359015e10584fa6327de0ce5a6a"

    const signature = utils.lotus.signMessage(client.fil.address, message)

    console.log(`Deploying contracts... (account)`)

    const account = await utils.deployContract(deployer, "AccountApiTest")

    const slicedSignature = signature.slice(2)

    const hexSig = `0x${slicedSignature}`
    const bytes = []
    for (let c = 0; c < hexSig.length; c += 2) {
        bytes.push(parseInt(hexSig.substr(c, 2), 16))
    }

    const _sig = Uint8Array.from([...bytes.slice(1)])

    const target = BigInt(utils.bytesToHex(client.fil.idAddress()))

    const params: AccountTypes.AuthenticateMessageParamsStruct = {
        signature: _sig,
        message: utils.hexToBytes(message),
    }

    //note: no additional checks performed
    //      it will revert if the signature/message is incorrect
    await account.eth.contract.authenticate_message(target, params)
    await utils.defaultTxDelay()

    const universalReceiverParams: CommonTypes.UniversalReceiverParamsStruct = {
        type_: BigInt(0),
        payload: Uint8Array.from([1, 2, 3]),
    }

    //note: no additional checks performed (reverts on error)
    await account.eth.contract.universal_receiver_hook(target, universalReceiverParams)
    await utils.defaultTxDelay()
}
