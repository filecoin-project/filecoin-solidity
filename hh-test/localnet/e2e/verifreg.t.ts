import { ethers } from "hardhat"
import { expect, util } from "chai"

import { VerifRegTypes, CommonTypes, VerifRegApiTest } from "../../../typechain-types/contracts/v0.8/tests/verifreg.test.sol/VerifRegApiTest"

import * as utils from "../../utils"

describe.only("Verifreg Test", () => {
    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    utils.setDebugMode(true)

    const { deployer, anyone } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (verifreg)`)

    const verifreg = await utils.deployContract(deployer, "VerifRegApiTest")

    //disable EVM RPC and restart localnet

    await utils.lotus.restart({ LOTUS_FEVM_ENABLEETHRPC: false })

    //add `verifreg` contract as verifier

    utils.lotus.registerVerifier(verifreg.fil.address, 16000000)

    //enable EVM RPC and restart localnet

    await utils.lotus.restart({ LOTUS_FEVM_ENABLEETHRPC: true })

    console.log({LOTUS_FEVM_ENABLEETHRPC: true})

    //add notary

    const addr: CommonTypes.FilAddressStruct = {
        data: utils.filAddressToBytes(anyone.fil.address),
    }

    const allowance: CommonTypes.BigIntStruct = {
        val: utils.hexToBytes(BigInt(1_000_000).toString(16)),
        neg: false,
    }
    const params: VerifRegTypes.AddVerifiedClientParamsStruct = {
        addr,
        allowance,
    }
    await verifreg.eth.contract.add_verified_client(params)

    // utils.lotus.registerNotary(verifreg.fil.address, 1_000_000)

    await utils.defaultTxDelay()

    console.log(`\n ---> Added verified Client !!! \n`)

    // process.exit()

    // const provider = 1333
    // const claim_ids = [0, 1, 2, 3, 4, 5, 6]
    // const params: VerifRegTypes.GetClaimsParamsStruct = {
    //     provider,
    //     claim_ids,
    // }
    // const res: VerifRegTypes.GetClaimsReturnStruct = await verifregContract.get_claims(params)

    // console.log({ res }, res.batch_info, res.claims)
}

const main = async () => {
    console.log(`Generating accounts...`)
    const [deployer, anyone] = utils.generate_f410_accounts(2)
    const [client] = await utils.generate_f3_accounts(1)
    const storageProvider = utils.getStorageProvider()

    console.log(`Funding generated wallets... (deployer, anyone and client)`)
    utils.lotus.sendFunds(deployer.fil.address, 10)
    utils.lotus.sendFunds(anyone.fil.address, 10)
    utils.lotus.sendFunds(client.fil.address, 10)

    await utils.defaultTxDelay()

    console.log(`DEBUG: clientIdAddress: ${client.fil.address}`)

    console.log(`Deploying contracts... (verifreg)`)

    const verifreg = await utils.deployContract(deployer, "VerifRegApiTest")

    console.log(`Contracts deployed:`)
    console.log({ verifreg })

    const notaryAmount = 100
    utils.lotus.registerNotary(verifreg.fil.address, notaryAmount)

    await utils.defaultTxDelay()

    const addr: CommonTypes.FilAddressStruct = {
        data: utils.filAddressToBytes(anyone.fil.address),
    }

    const allowance: CommonTypes.BigIntStruct = {
        val: utils.hexToBytes("0x0a"),
        neg: false,
    }
    const params: VerifRegTypes.AddVerifiedClientParamsStruct = {
        addr,
        allowance,
    }
    await verifreg.eth.contract.add_verified_client(params)

    await utils.defaultTxDelay()

    console.log(`\n ---> Added verified Client !!! \n`)

    process.exit()
}
