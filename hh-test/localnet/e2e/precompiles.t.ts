import { ethers } from "hardhat"
import { expect, util } from "chai"

import * as utils from "../../utils"

import { CommonTypes } from "../../../typechain-types/contracts/v0.8/tests/precompiles.test.sol/PrecompilesApiTest"

describe("Precompiles Test", () => {
    beforeEach(async () => {})

    it("Test 1: Integration test port", async () => {
        await test1()
    })
})

const test1 = async () => {
    const { deployer, anyone, client: f3Addr } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (PrecompilesApiTest)`)

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
