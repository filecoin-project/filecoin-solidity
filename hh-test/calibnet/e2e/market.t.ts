import { ethers } from "hardhat"
import { expect } from "chai"

import { MarketTypes, CommonTypes } from "../../../typechain-types/contracts/v0.8/tests/market.test.sol/MarketApiTest"

import * as utils from "../../utils"

import { CHECKING_DEAL_IDS, EXPECTED_DEAL_INFO, getActualDealInfo } from "../_common"

describe("Market Test", () => {
    const DBG_TESTS = {}
    let currentTestName: string

    let market, deployer

    before(async () => {
        const { deployer: _deployer } = await utils.performGeneralSetupOnCalibnet()
        deployer = _deployer
        market = await utils.deployContract(deployer, "MarketApiTest")
    })

    beforeEach(function () {
        currentTestName = this.currentTest.title
        DBG_TESTS[currentTestName] = true
    })

    it("Test 1: State changes on Calibnet", async () => {
        await test1(currentTestName, { deployer, market })
        DBG_TESTS[currentTestName] = false
    })
    it("Test 2: Reading from Calibnet", async () => {
        await test2(currentTestName, { deployer, market })
        DBG_TESTS[currentTestName] = false
    })

    afterEach(() => {
        if (DBG_TESTS[currentTestName]) {
            utils.printDbgLog(currentTestName)
        }
    })
})
const test1 = async (testName: string, { deployer, market }) => {
    const dbg = utils.initDbg(testName)

    let amount = BigInt(10 ** 18)

    const targetByteAddr = utils.filAddressToBytes(market.fil.address)

    dbg(`Adding funds to balance...`)

    const previousBalance: MarketTypes.GetBalanceReturnStruct = await market.eth.contract.get_balance({ data: targetByteAddr })

    await market.eth.contract.add_balance({ data: targetByteAddr }, amount, { gasLimit: 1_000_000_000, value: amount })
    await utils.defaultTxDelay(2)

    let previousBalanceBigInt = BigInt(previousBalance.balance.val as string)

    let expectedClientBalance = { val: utils.bigIntToHexString(previousBalanceBigInt + amount), neg: false }

    let actualClientBalance: MarketTypes.GetBalanceReturnStruct = await market.eth.contract.get_balance({ data: targetByteAddr })

    expect(actualClientBalance.balance.val).to.eq(expectedClientBalance.val)
    expect(actualClientBalance.balance.neg).to.eq(expectedClientBalance.neg)

    dbg(`Withdrawing funds from balance...`)

    amount = BigInt(100)
    const tokenAmount = { val: Uint8Array.from([100]), neg: false }

    const withdrawalParams: MarketTypes.WithdrawBalanceParamsStruct = {
        provider_or_client: { data: targetByteAddr },
        tokenAmount,
    }

    await market.eth.contract.withdraw_balance(withdrawalParams, { gasLimit: 1_000_000_000 })
    await utils.defaultTxDelay(4)

    previousBalanceBigInt = BigInt(actualClientBalance.balance.val as string)

    expectedClientBalance = { val: utils.bigIntToHexString(previousBalanceBigInt - amount), neg: false }

    actualClientBalance = await market.eth.contract.get_balance({ data: targetByteAddr })

    expect(actualClientBalance.balance.val).to.eq(expectedClientBalance.val)
    expect(actualClientBalance.balance.neg).to.eq(expectedClientBalance.neg)
}

const test2 = async (testName: string, { deployer, market }) => {
    const dbg = utils.initDbg(testName)

    for (const dealID of CHECKING_DEAL_IDS) {
        const actualDealInfo = await getActualDealInfo(market, dealID)
        const expectedDealInfo = EXPECTED_DEAL_INFO[dealID]

        expect(actualDealInfo.dealCommitment.data).to.eq(expectedDealInfo.dealCommitment.data)
        expect(actualDealInfo.dealCommitment.size).to.eq(expectedDealInfo.dealCommitment.size)

        expect(actualDealInfo.dealClientId).to.eq(expectedDealInfo.dealClientId)
        expect(actualDealInfo.dealProviderId).to.eq(expectedDealInfo.dealProviderId)

        expect(actualDealInfo.dealLabel.data).to.eq(expectedDealInfo.dealLabel.data)
        expect(actualDealInfo.dealLabel.isString).to.eq(expectedDealInfo.dealLabel.isString)

        expect(actualDealInfo.dealTotalPrice.val).to.eq(expectedDealInfo.dealTotalPrice.val)
        expect(actualDealInfo.dealTotalPrice.neg).to.eq(expectedDealInfo.dealTotalPrice.neg)

        expect(actualDealInfo.dealClientCollateral.val).to.eq(expectedDealInfo.dealClientCollateral.val)
        expect(actualDealInfo.dealClientCollateral.neg).to.eq(expectedDealInfo.dealClientCollateral.neg)
        expect(actualDealInfo.dealProviderCollateral.val).to.eq(expectedDealInfo.dealProviderCollateral.val)
        expect(actualDealInfo.dealProviderCollateral.neg).to.eq(expectedDealInfo.dealProviderCollateral.neg)

        expect(actualDealInfo.dealVerified).to.eq(expectedDealInfo.dealVerified)
        expect(actualDealInfo.dealActivation.activated).to.eq(expectedDealInfo.dealActivation.activated)
        expect(actualDealInfo.dealActivation.terminated).to.eq(expectedDealInfo.dealActivation.terminated)
    }
}
