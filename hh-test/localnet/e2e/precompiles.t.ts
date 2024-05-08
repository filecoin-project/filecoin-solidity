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
    const { deployer, anyone, client: f3Addr } = await utils.performGeneralSetup()

    dbg(`Deploying contracts... (PrecompilesApiTest)`)

    const precompilesSC = await utils.deployContract(deployer, "PrecompilesApiTest")

    //resolving address
    const addr: CommonTypes.FilAddressStruct = {
        data: utils.filAddressToBytes(anyone.fil.address),
    }

    const expectedResolvedAddr = utils.lotus.findIDAddressToBigInt(anyone.fil.address)
    const actualResolvedAddr = await precompilesSC.eth.contract.resolve_address(addr)

    expect(actualResolvedAddr).to.eq(expectedResolvedAddr)

    //resolving empty delegated address
    const actorId = utils.lotus.findIDAddressToBigInt(f3Addr.fil.address)
    const expectedDelegatedAddr = "0x"
    const actualDelegatedAddr = await precompilesSC.eth.contract.lookup_delegated_address(actorId)

    expect(actualDelegatedAddr).to.eq(expectedDelegatedAddr)

    //resolving non-empty delegated address
    const actorId2 = utils.lotus.findIDAddressToBigInt(anyone.fil.address)
    const expectedDelegatedAddr2 = utils.bytesToHex(utils.filAddressToBytes(anyone.fil.address))
    const actualDelegatedAddr2 = await precompilesSC.eth.contract.lookup_delegated_address(actorId2)

    expect(actualDelegatedAddr2).to.eq(expectedDelegatedAddr2)

    //resolving eth address
    const expectedIdForEthAddress = utils.lotus.findIDAddressToBigInt(anyone.fil.address)
    const actualIdForEthAddr = await precompilesSC.eth.contract.resolve_eth_address(anyone.eth.address)

    expect(actualIdForEthAddr).to.eq(expectedIdForEthAddress)
}
