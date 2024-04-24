import { ethers } from "hardhat"
import { expect, util } from "chai"

import { bls12_381 as bls } from "@noble/curves/bls12-381"

import { FilecoinClient } from "@blitslabs/filecoin-js-signer"

const loadBls = require("bls-signatures")

const endpoint = "https://calibration.node.glif.io"
const token = ""
const filecoin_client = new FilecoinClient(endpoint, token)

import { CommonTypes, AccountTypes } from "../../../typechain-types/contracts/v0.8/tests/account.test.sol/AccountApiTest"

import * as utils from "../../utils"

describe("Account Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    return
    var BLS = await loadBls()
    console.log("bls")
    var seed = Uint8Array.from([
        0, 50, 6, 244, 24, 199, 1, 25, 52, 88, 192, 19, 18, 12, 89, 6, 220, 18, 102, 58, 209, 82, 12, 62, 89, 110, 182, 9, 44, 20, 254, 22,
    ])

    var sk = BLS.AugSchemeMPL.key_gen(seed)
    var pk = sk.get_g1()

    var message2 = Uint8Array.from([1, 2, 3, 4, 5])
    var signature2 = BLS.AugSchemeMPL.sign(sk, message2)

    let ok = BLS.AugSchemeMPL.verify(pk, message2, signature2)

    var signatureBytes = signature2.serialize()

    console.log({ ok, signature2, sigBytes: BLS.Util.hex_str(signatureBytes) })

    const { deployer, clientSignMessage } = await utils.performGeneralSetupOnCalibnet()

    await utils.defaultTxDelay()

    const message =
        "8eabea2a4001061ac4c9fe3c517725b8829b159149a863b2a2320cc628d026a871d3cb34947371f384a9eb49ff9bd56a019fa70e10c06ac5ca93df3c1d6f54d540c57cbe2f5209cafdc12146d5d59172dd4d8359015e10584fa6327de0ce5a6a"

    const publicKey = bls.getPublicKey(process.env.F3_PK)
    const rawSignature = bls.sign(message, process.env.F3_PK)
    const signature = utils.bytesToHex(rawSignature).slice(2)
    const isValid = bls.verify(signature, message, publicKey)

    console.log({ isValid, signature, rawSignature })

    // process.exit(1)

    // const signature = await clientSignMessage(message)

    console.log(`Deploying contracts... (account)`)

    const account = await utils.deployContract(deployer, "AccountApiTest")

    console.log({ account })

    // const slicedSignature = signature.slice(2)
    const slicedSignature = signature

    const hexSig = `0x${slicedSignature}`
    const bytes = []
    for (let c = 0; c < hexSig.length; c += 2) {
        bytes.push(parseInt(hexSig.substr(c, 2), 16))
    }

    const _sig = Uint8Array.from([...bytes.slice(1)])

    const target = BigInt(process.env.F3_ID)

    const params: AccountTypes.AuthenticateMessageParamsStruct = {
        signature: rawSignature,
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
