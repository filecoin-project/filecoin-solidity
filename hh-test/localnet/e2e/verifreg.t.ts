import { ethers } from "hardhat"
import { expect, util } from "chai"

import { VerifRegTypes, CommonTypes, VerifRegApiTest } from "../../../typechain-types/contracts/v0.8/tests/verifreg.test.sol/VerifRegApiTest"

import * as utils from "../../utils"

describe.only("Verifreg Test", () => {
    beforeEach(async () => {
        // await utils.lotus.restart({ LOTUS_FEVM_ENABLEETHRPC: true })
    })

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer, anyone, storageProvider } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (verifreg)`)

    const verifreg = await utils.deployContract(deployer, "VerifRegApiTest")

    //disable EVM RPC and restart localnet

    await utils.lotus.restart({ LOTUS_FEVM_ENABLEETHRPC: false })

    //add `verifreg` contract as verifier

    utils.lotus.registerVerifier(verifreg.fil.address, 16000000)

    //enable EVM RPC and restart localnet

    await utils.lotus.restart({ LOTUS_FEVM_ENABLEETHRPC: true })

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
    await utils.defaultTxDelay()

    console.log(`\n ---> Added verified Client !!! \n`)

    const claim_ids = [0, 1]
    const getClaimsParams: VerifRegTypes.GetClaimsParamsStruct = {
        provider: storageProvider.fil.id,
        claim_ids,
    }
    const res: VerifRegTypes.GetClaimsReturnStruct = await verifreg.eth.contract.get_claims(getClaimsParams)

    console.log("get_claims()", { res }, res.batch_info, res.claims)

    const removeParams: VerifRegTypes.RemoveExpiredAllocationsParamsStruct = {
        client: BigInt(0x65),
        allocation_ids: [],
    }

    await verifreg.eth.contract.remove_expired_allocations(removeParams)
    await utils.defaultTxDelay()

    console.log("remove_expired_allocations() - done")
}
