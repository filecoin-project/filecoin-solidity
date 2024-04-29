import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"
import { CommonTypes, DataCapTypes } from "../../../typechain-types/contracts/v0.8/tests/datacap.test.sol/DataCapApiTest"

describe("Datacap Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { client, deployer, anyone: user } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (DataCapApiTest)`)

    const DataCapFactory = await ethers.getContractFactory("DataCapApiTest")
    const datacap = await utils.deployContract(deployer, "DataCapApiTest")

    const pDatacap = await utils.upgradeToDataCapProxy(deployer, DataCapFactory, await datacap.eth.contract.getAddress())
    await utils.defaultTxDelay()

    console.log({ pDatacapAddr: utils.ethAddressToFilAddress(await pDatacap.getAddress()) })

    const expectedName = "DataCap"
    const actualName = await pDatacap.name()

    expect(actualName).to.eq(expectedName)

    const expectedSymbol = "DCAP"
    const actualSymbol = await pDatacap.symbol()

    expect(actualSymbol).to.eq(expectedSymbol)

    const expectedTotalSupply = {
        val: "0x0d3c57f2b67c9feea00000",
        neg: false,
    }

    const actualTotalSupply = await pDatacap.total_supply()

    expect(actualTotalSupply.val).to.eq(expectedTotalSupply.val)
    expect(actualTotalSupply.neg).to.eq(expectedTotalSupply.neg)

    const addr: CommonTypes.FilAddressStruct = { data: Uint8Array.from([0, 66]) }
    const expectedBalance: CommonTypes.BigIntStruct = { val: "0x", neg: false }
    const actualBalance: CommonTypes.BigIntStruct = await pDatacap.balance(addr)

    expect(actualBalance.neg).to.eq(expectedBalance.neg)
    expect(actualBalance.val).to.eq(expectedBalance.val)

    const allowanceParams: DataCapTypes.GetAllowanceParamsStruct = {
        owner: {
            data: utils.filAddressToBytes(user.fil.address),
        },
        operator: {
            data: utils.filAddressToBytes(user.fil.address),
        },
    }
    const expectedAllowance: CommonTypes.BigIntStruct = { val: "0x", neg: false }
    const actualAllowance: CommonTypes.BigIntStruct = await pDatacap.allowance(allowanceParams)

    expect(actualAllowance.neg).to.eq(expectedAllowance.neg)
    expect(actualAllowance.val).to.eq(expectedAllowance.val)

    console.log("calling transfer")

    const transferParams: DataCapTypes.TransferParamsStruct = {
        to: {
            data: Uint8Array.from([0x00, 0x06]),
        },
        amount: {
            val: utils.hexToBytes("0x" + (BigInt(10000000000) * BigInt(100000000)).toString(16)),
            neg: false,
        },
        operator_data: Uint8Array.from([]),
    }

    await pDatacap.transfer(transferParams)
    //TODO: compare

    console.log("calling transferFrom")

    const transferFromParams: DataCapTypes.TransferFromParamsStruct = {
        from: { data: utils.filAddressToBytes(user.fil.address) },
        to: {
            data: Uint8Array.from([0, 0xc8, 0x01]), // utils.filAddressToBytes()
        },
        amount: {
            val: utils.hexToBytes("0x3782DACE9D900000"),
            neg: false,
        },
        operator_data: Uint8Array.from([]),
    }

    await pDatacap.transferFrom(transferFromParams)

    //TODO: compare

    console.log(`calling burn`)

    const expectedBurnAmount: CommonTypes.BigIntStruct = {
        val: utils.hexToBytes("0x360C2789AAE8740000"),
        neg: false,
    }

    const burnAmount: CommonTypes.BigIntStruct = {
        val: utils.hexToBytes("0x0DE0B6B3A7640000"),
        neg: false,
    }

    await pDatacap.burn(burnAmount)

    //TODO: compare

    console.log(`calling burnFrom`)

    const burnFromAmount = burnAmount

    const expectedBurnFromAmount: DataCapTypes.BurnFromReturnStruct = {
        balance: {
            val: utils.hexToBytes("0x35F0661C4399AC0000"),
            neg: false,
        },
        allowance: {
            val: utils.hexToBytes("0x02F050FE938943ACC41A01C4FDBB0C0000"),
            neg: false,
        },
    }

    await pDatacap.burnFrom(burnFromAmount)

    //TODO: compare

    console.log(`calling allowance`)

    const allowanceParams_2: DataCapTypes.GetAllowanceParamsStruct = {
        owner: {
            data: utils.filAddressToBytes(deployer.fil.address),
        },
        operator: {
            data: utils.filAddressToBytes(client.fil.address),
        },
    }

    //TODO: compare

    console.log(`calling increase_allowance`)

    console.log(`calling decrease_allowance`)

    console.log(`calling revoke_allowance`)
}
