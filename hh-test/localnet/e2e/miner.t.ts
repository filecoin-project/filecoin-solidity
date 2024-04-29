import { ethers } from "hardhat"
import { expect, util } from "chai"

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
    console.log({ minerSC })

    utils.lotus.changeMinerOwner(minerSC.fil.address)
    await utils.defaultTxDelay()

    console.log(`Change owner proposed.`)

    const target = 1000

    // const newBeneficiary: CommonTypes.FilAddressStruct = { data: Uint8Array.from([0, ...Array.from(minerSC.fil.idAddress())]) }
    const newBeneficiary: CommonTypes.FilAddressStruct = { data: minerSC.fil.idAddress() }
    // const newBeneficiary: CommonTypes.FilAddressStruct = { data: Uint8Array.from([0, 0x66]) }

    console.log({ newBeneficiary })

    const enc = await minerSC.eth.contract.encodeFilAddress(newBeneficiary)
    const enc2 = await minerSC.eth.contract.encodeFilAddress({ data: minerSC.fil.byteAddress })

    console.log({ enc, enc2 })

    try {
        await minerSC.eth.contract.change_owner_address(target, newBeneficiary)
        await utils.defaultTxDelay()
    } catch {
        const popTx = await minerSC.eth.contract.change_owner_address.populateTransaction(target, newBeneficiary)
        utils.lotus.evmInvoke(minerSC.fil.address, popTx.data)
    }
    console.log(`Change owner completed!`)

    // const target = storageProvider.fil.id

    //...

    // const owner = await minerSC.eth.contract.get_owner(target)

    const workerBytes = utils.filAddressToBytes(worker.fil.address)
    console.log({ worker, workerBytes, hexWorker: utils.bytesToHex(workerBytes) })

    //.....

    // const addr: CommonTypes.FilAddressStruct = { data: storageProvider.fil.byteAddress }
    // const addr: CommonTypes.FilAddressStruct = { data: Uint8Array.from([0x00, 0x03, 0xec]) }
    const addr: CommonTypes.FilAddressStruct = { data: minerSC.fil.idAddress() }

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
