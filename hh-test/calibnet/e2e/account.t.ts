import { ethers } from "hardhat"
import { expect, util } from "chai"

import { CommonTypes, AccountTypes } from "../../../typechain-types/contracts/v0.8/tests/account.test.sol/AccountApiTest"

import * as utils from "../../utils"

describe.only("Account Test", () => {
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

    const message =
        "8eabea2a4001061ac4c9fe3c517725b8829b159149a863b2a2320cc628d026a871d3cb34947371f384a9eb49ff9bd56a019fa70e10c06ac5ca93df3c1d6f54d540c57cbe2f5209cafdc12146d5d59172dd4d8359015e10584fa6327de0ce5a6a"

    //note: the following code snippet is the way the `signature` variable value was generated
    const user = utils.lotus.importDefaultWallets()
    const _signature = utils.lotus.signMessage(user.fil.address, message)

    const signature =
        "02b179ef5bdedaffffdd5a8c245c7e3a9629329b7870ee56eff12dbbc5479cebaae70233d708b37d1ff57ccab813c22aa80a9ea5d8fd8df5364d3dc71e024e1ffd872d87c2c60cab54966aac4f6b1fee4b0b3c663dde7d6d525a26f57e569452c5"

    expect(_signature).to.eq(signature)

    dbg(`Deploying contracts... (account)`)

    const account = await utils.deployContract(deployer, "AccountApiTest")

    const slicedSignature = signature.slice(2)

    const hexSig = `0x${slicedSignature}`
    const bytes = []
    for (let c = 0; c < hexSig.length; c += 2) {
        bytes.push(parseInt(hexSig.substr(c, 2), 16))
    }

    const _sig = Uint8Array.from([...bytes.slice(1)])

    const target = BigInt(process.env.F3_ID)

    const params: AccountTypes.AuthenticateMessageParamsStruct = {
        signature: _sig,
        message: utils.hexToBytes(message),
    }

    dbg(`Authenticating message...`)

    //note: no additional checks performed
    //      it will revert if the signature/message is incorrect
    await account.eth.contract.authenticate_message(target, params)

    dbg(`Calling universal hook...`)

    const universalReceiverParams: CommonTypes.UniversalReceiverParamsStruct = {
        type_: BigInt(0),
        payload: Uint8Array.from([1, 2, 3]),
    }

    //note: no additional checks performed (reverts on error)
    await account.eth.contract.universal_receiver_hook(target, universalReceiverParams)
    await utils.defaultTxDelay()
}
