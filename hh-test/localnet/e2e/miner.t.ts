import { ethers } from "hardhat"
import { expect, util } from "chai"

/*

lotus send --method 2 -—params-hex 85420067583103a27f8f61995da2205e0fe541598fee7f2273455c3a1b15afa5b6a706c0912f13a1581f8ac28618abdfe13a8bc31aa5c00a430102038143010203 t04 0
lotus send --method 2 —-params-hex 854200675831035d733f4beef4e9af1cc73c8e3a053b2c7cb58e0cb4d8234befa28a3811c4630fa73db64b69a0ac5a33cd7b18938f0a430102038143010203 t04 0
*/

import * as utils from "../../utils"
import { CommonTypes, MinerTypes } from "../../../typechain-types/contracts/v0.8/tests/miner.test.sol/MinerApiTest"

describe("Miner Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer, storageProvider, client: worker } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (MinerApiTest)`)

    const minerSC = await utils.deployContract(deployer, "MinerApiTest")

    // const target = storageProvider.fil.id
    const target = 0x65

    //...

    // const owner = await minerSC.eth.contract.get_owner(target)

    const workerBytes = utils.filAddressToBytes(worker.fil.address)
    console.log({ worker, workerBytes, hexWorker: utils.bytesToHex(workerBytes) })

    //.....

    // const addr: CommonTypes.FilAddressStruct = { data: storageProvider.fil.byteAddress }
    const addr: CommonTypes.FilAddressStruct = { data: Uint8Array.from([0x00, 0x65]) }

    console.log({ target, addr })

    const popTx = await minerSC.eth.contract.change_owner_address.populateTransaction(target, addr)
    console.log({ scAddr: minerSC.fil.address, popTx })
    await minerSC.eth.contract.change_owner_address(target, addr)

    console.log("change_owner_address finished")

    const expectedBeneficiary: [MinerTypes.ActiveBeneficiaryStruct, MinerTypes.PendingBeneficiaryChangeStruct] = [
        {
            beneficiary: {
                data: Uint8Array.from([0x00, 0x67]),
            },
            term: {
                quota: {
                    val: "0x",
                    neg: false,
                },
                used_quota: {
                    val: "0x",
                    neg: false,
                },
                expiration: BigInt(0),
            },
        },
        {
            new_beneficiary: { data: "0x" },
            new_expiration: BigInt(0),
            new_quota: { val: "0x", neg: false },
            approved_by_beneficiary: false,
            approved_by_nominee: false,
        },
    ]
    const actualBeneficiary: MinerTypes.ActiveBeneficiaryStruct = await minerSC.eth.contract.get_beneficiary(target)
    console.log({ expectedBeneficiary, actualBeneficiary })
}
