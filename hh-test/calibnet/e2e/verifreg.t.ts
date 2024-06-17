import { ethers } from "hardhat"
import { expect, util } from "chai"

import { VerifRegTypes, CommonTypes, VerifRegApiTest } from "../../../typechain-types/contracts/v0.8/tests/verifreg.test.sol/VerifRegApiTest"

import * as utils from "../../utils"

describe("Verifreg Test", () => {
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

    dbg(`Deploying contracts... (verifreg)`)

    const VerifRegFactory = await ethers.getContractFactory("VerifRegApiTest")
    const verifreg = await utils.deployContract(deployer, "VerifRegApiTest")

    const storageProviderId = 1000
    const claim_ids = [0, 1]
    const getClaimsParams: VerifRegTypes.GetClaimsParamsStruct = {
        provider: storageProviderId,
        claim_ids,
    }
    const res: VerifRegTypes.GetClaimsReturnStruct = await verifreg.eth.contract.get_claims(getClaimsParams)

    const removeAllocationParams: VerifRegTypes.RemoveExpiredAllocationsParamsStruct = {
        client: BigInt(0x65),
        allocation_ids: [],
    }

    dbg(`Removing allocations...`)

    await verifreg.eth.contract.remove_expired_allocations(removeAllocationParams)
    await utils.defaultTxDelay()

    const removeClaimParams: VerifRegTypes.RemoveExpiredClaimsParamsStruct = {
        provider: BigInt(0x66),
        claim_ids,
    }

    dbg(`Removing expired claims...`)

    await verifreg.eth.contract.remove_expired_claims(removeClaimParams)
    await utils.defaultTxDelay()
}
