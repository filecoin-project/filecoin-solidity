import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

import { CommonTypes } from "../../../typechain-types/contracts/v0.8/tests/precompiles.test.sol/PrecompilesApiTest"

describe("Precompiles Test", () => {
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

    dbg(`Deploying contracts... (PrecompilesApiTest)`)

    const precompilesSC = await utils.deployContract(deployer, "PrecompilesApiTest")

    const targetF3Addr = "t3wybme2dab6l3h4zuuzxxteztmtq7jyh6qgrko3urkvhjfqdr33vsus4x5s2ccpuhhc5xscpx3bcpufsf6vzq"
    const actorId = BigInt(112484)

    //resolving address
    const addr: CommonTypes.FilAddressStruct = {
        data: utils.filAddressToBytes(targetF3Addr),
    }

    const expectedResolvedAddr = actorId
    const actualResolvedAddr = await precompilesSC.eth.contract.resolve_address(addr)

    expect(actualResolvedAddr).to.eq(expectedResolvedAddr)

    //resolving empty delegated address (F3 addr type)
    const expectedDelegatedAddr = "0x"
    const actualDelegatedAddr = await precompilesSC.eth.contract.lookup_delegated_address(actorId)

    expect(actualDelegatedAddr).to.eq(expectedDelegatedAddr)

    //resolving non-empty delegated address
    const ethTargetAddr = "0x5E2E67CC130D09438117D404AAAc53e49997DC4F"

    const targetAddr = utils.ethAddressToFilAddress(ethTargetAddr)
    const actorId2 = BigInt(114105)
    const expectedDelegatedAddr2 = utils.bytesToHex(utils.filAddressToBytes(targetAddr))
    const actualDelegatedAddr2 = await precompilesSC.eth.contract.lookup_delegated_address(actorId2)

    expect(actualDelegatedAddr2).to.eq(expectedDelegatedAddr2)

    //resolving eth address
    const expectedIdForEthAddress = actorId2
    const actualIdForEthAddr = await precompilesSC.eth.contract.resolve_eth_address(ethTargetAddr)

    expect(actualIdForEthAddr).to.eq(expectedIdForEthAddress)
}
