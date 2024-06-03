import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"
import { CommonTypes, DataCapTypes } from "../../../typechain-types/contracts/v0.8/tests/datacap.test.sol/DataCapApiTest"

describe("Datacap Test", () => {
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

    const { client, deployer, anyone: user } = await utils.performGeneralSetup()

    dbg(`Deploying contracts... (DataCapApiTest)`)

    const DataCapFactory = await ethers.getContractFactory("DataCapApiTest")
    const datacap = await utils.deployContract(deployer, "DataCapApiTest")

    const pDatacap = await utils.upgradeToDataCapProxy(deployer, DataCapFactory, await datacap.eth.contract.getAddress())
    await utils.defaultTxDelay()

    dbg(JSON.stringify({ pDatacapAddr: utils.ethAddressToFilAddress(await pDatacap.getAddress()) }))

    dbg("calling 'name'")

    const expectedName = "DataCap"
    const actualName = await pDatacap.name()

    expect(actualName).to.eq(expectedName)

    dbg("calling 'symbol'")

    const expectedSymbol = "DCAP"
    const actualSymbol = await pDatacap.symbol()

    expect(actualSymbol).to.eq(expectedSymbol)

    const expectedTotalSupply = {
        val: "0x3635c9adc5dea00000", // 1000 FIL (1e21 attoFIL) minted during setup
        neg: false,
    }

    dbg("calling 'total_supply'")

    const actualTotalSupply = await pDatacap.total_supply()

    expect(actualTotalSupply.val).to.eq(expectedTotalSupply.val)
    expect(actualTotalSupply.neg).to.eq(expectedTotalSupply.neg)

    dbg("calling 'balance'")

    const addr: CommonTypes.FilAddressStruct = { data: Uint8Array.from([0, 66]) }
    const expectedBalance: CommonTypes.BigIntStruct = { val: "0x", neg: false }
    const actualBalance: CommonTypes.BigIntStruct = await pDatacap.balance(addr)

    expect(actualBalance.neg).to.eq(expectedBalance.neg)
    expect(actualBalance.val).to.eq(expectedBalance.val)

    dbg("calling 'allowance'")

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
}
