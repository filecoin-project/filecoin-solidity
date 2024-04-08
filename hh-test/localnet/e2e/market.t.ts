import { ethers } from "hardhat"
import { expect } from "chai"

import { MarketTypes, CommonTypes } from "../../../typechain-types/contracts/v0.8/tests/market.test.sol/MarketApiTest"

import * as utils from "../../utils"

describe.only("Market Tests", () => {
    it("Test 1: Basic Deal Flow", async () => await test1())
    // it("Dbg", async () => await _dbg())
})
const _dbg = async () => {
    const address = "t3sqsp7sm7vaovx27pn5wsexsgv2jfzbgcimir7tw2u4ntape6ffldi33gdktsovvjversphc2s3tludnhu2xa"
    const result = utils.lotus.findIDAddressToBytes(address)
    const bigIntResult = utils.idAddressToBigInt(result)
    console.log({ address, result, bigIntResult })

    const start_epoch = BigInt(10000)
    const end_epoch = BigInt(10000 + (545150 - 25245))
    const storage_price_per_epoch = BigInt(1)

    const res = `0x${((end_epoch - start_epoch) * storage_price_per_epoch).toString(16)}`

    console.log({ res })
}

const test1 = async () => {
    //test scenario adopted from rust integration tests

    utils.setDebugMode(true)

    const { deployer, anyone, client, storageProvider } = await utils.performGeneralSetup()

    console.log(`Deploying contracts... (market and helper)`)

    const market = await utils.deployContract(deployer, "MarketApiTest")
    const helper = await utils.deployContract(deployer, "MarketHelper")

    console.log(`Contracts deployed:`)
    console.log({ market, helper })

    console.log(`Setting miner control address to market.eth.contract: ${market.fil.address}`)
    utils.lotus.setControlAddress(market.fil.address)

    console.log(`Funding Escrows... (client and provider)`)
    const amount = BigInt(10 ** 18)

    await market.eth.contract.add_balance({ data: client.fil.byteAddress }, amount, { gasLimit: 1_000_000_000, value: amount })

    await utils.defaultTxDelay()

    await market.eth.contract.add_balance({ data: storageProvider.fil.byteAddress }, amount, { gasLimit: 1_000_000_000, value: amount })

    await utils.defaultTxDelay()

    const expectedClientBalance = { val: utils.bigIntToHexString(amount), neg: false }

    const actualClientBalance: MarketTypes.GetBalanceReturnStruct = await market.eth.contract.get_balance({ data: client.fil.byteAddress })

    console.log({ expectedClientBalance, actualClientBalance })

    expect(actualClientBalance.balance.val).to.eq(expectedClientBalance.val)
    expect(actualClientBalance.balance.neg).to.eq(expectedClientBalance.neg)

    console.log(`Generating deal params...`)
    const { deal, dealDebug } = utils.generateDealParams(client.fil.address, storageProvider.fil.address)
    const serializedDealProposal = (await helper.eth.contract.serialize_deal_proposal(deal.proposal)).slice(2)

    const signedDealProposal = utils.lotus.signMessage(client.fil.address, serializedDealProposal)

    deal.client_signature = utils.hexToBytes(signedDealProposal)

    console.log(`Publishing deal...`) //Note: Anyone can issue the publishing transaction

    await market.eth.contract.connect(anyone.eth.signer).publish_storage_deals({ deals: [deal] }, { gasLimit: 1_000_000_000 })

    await utils.defaultTxDelay()

    //Asertions

    //Expected values
    const expectedDealCommitment: MarketTypes.GetDealDataCommitmentReturnStruct = {
        data: ethers.hexlify(Uint8Array.from([0, ...Array.from(ethers.getBytes(deal.proposal.piece_cid.data))])),
        size: deal.proposal.piece_size,
    }
    const expectedDealClientId = utils.idAddressToBigInt(client.fil.idAddress)
    const expectedDealProviderId = utils.idAddressToBigInt(storageProvider.fil.idAddress)

    const expectedDealLabel: CommonTypes.DealLabelStruct = { data: utils.bytesToHex(deal.proposal.label.data as Uint8Array), isString: true }

    const expectedDealTerm: MarketTypes.GetDealTermReturnStruct = {
        start: deal.proposal.start_epoch,
        duration: dealDebug.end_epoch - dealDebug.start_epoch,
    }

    const expectedDealTotalPrice = dealDebug.total_price

    const expectedDealClientCollateral = utils.bigIntStructWithStringFormat(deal.proposal.client_collateral)
    const expectedDealProviderCollateral = utils.bigIntStructWithStringFormat(deal.proposal.provider_collateral)

    const expectedDealVerified = false
    const expectedDealActivation: MarketTypes.GetDealActivationReturnStruct = {
        activated: BigInt(0),
        terminated: BigInt(0),
    }

    console.log(`EXPECTED:`, {
        expectedDealCommitment,
        expectedDealClientId,
        expectedDealProviderId,
        expectedDealLabel,
        expectedDealTerm,
        expectedDealTotalPrice,
        expectedDealClientCollateral,
        expectedDealProviderCollateral,
        expectedDealVerified,
        expectedDealActivation,
    })

    //Actual values
    const dealID = await market.eth.contract.publishedDealIds(0)
    const actualDealCommitment: MarketTypes.GetDealDataCommitmentReturnStruct = await market.eth.contract.get_deal_data_commitment(dealID)
    const actualDealClientId = await market.eth.contract.get_deal_client(dealID)
    const actualDealProviderId = await market.eth.contract.get_deal_provider(dealID)
    const actualDealLabel: CommonTypes.DealLabelStruct = await market.eth.contract.get_deal_label(dealID)
    const actualDealTerm: MarketTypes.GetDealTermReturnStruct = await market.eth.contract.get_deal_term(dealID)
    const actualDealTotalPrice: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_total_price(dealID)
    const actualDealClientCollateral: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_client_collateral(dealID)
    const actualDealProviderCollateral: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_provider_collateral(dealID)

    const actualDealVerified = await market.eth.contract.get_deal_verified(dealID)
    const actualDealActivation: MarketTypes.GetDealActivationReturnStruct = await market.eth.contract.get_deal_activation(dealID)

    console.log(`ACTUAL:`, {
        dealID,
        actualDealClientId,
        actualDealClientCollateral,
        actualDealProviderCollateral,
        actualDealProviderId,
        actualDealLabel,
        actualDealTerm,
        actualDealTotalPrice,
        actualDealCommitment,
        actualDealVerified,
        actualDealActivation,
    })

    //Comparison checks
    expect(actualDealCommitment.data).to.eq(expectedDealCommitment.data)
    expect(actualDealCommitment.size).to.eq(expectedDealCommitment.size)

    expect(actualDealClientId).to.eq(expectedDealClientId)
    expect(actualDealProviderId).to.eq(expectedDealProviderId)

    expect(actualDealLabel.data).to.eq(expectedDealLabel.data)
    expect(actualDealLabel.isString).to.eq(expectedDealLabel.isString)

    expect(actualDealTerm.start).to.eq(expectedDealTerm.start)
    expect(actualDealTerm.duration).to.eq(expectedDealTerm.duration)

    expect(actualDealTotalPrice.val).to.eq(expectedDealTotalPrice.val)
    expect(actualDealTotalPrice.neg).to.eq(expectedDealTotalPrice.neg)

    expect(actualDealClientCollateral.val).to.eq(expectedDealClientCollateral.val)
    expect(actualDealClientCollateral.neg).to.eq(expectedDealClientCollateral.neg)
    expect(actualDealProviderCollateral.val).to.eq(expectedDealProviderCollateral.val)
    expect(actualDealProviderCollateral.neg).to.eq(expectedDealProviderCollateral.neg)

    expect(actualDealVerified).to.eq(expectedDealVerified)
    expect(actualDealActivation.activated).to.eq(expectedDealActivation.activated)
    expect(actualDealActivation.terminated).to.eq(expectedDealActivation.terminated)
}
