import { ethers } from "hardhat"
import { expect } from "chai"

import { MarketTypes, CommonTypes } from "../../../typechain-types/contracts/v0.8/tests/market.test.sol/MarketApiTest"

import * as utils from "../../utils"

describe("Market Test", () => {
    it("is_OK", async () => {
        await main()
    })
})

const main = async () => {
    console.log(`Generating accounts...`)
    const [deployer, anyone] = utils.generate_f410_accounts(2)
    const [client] = await utils.generate_f3_accounts(1)
    const storageProvider = utils.getStorageProvider()

    console.log(`Generated:`)
    console.log({ deployer })
    console.log({ anyone })
    console.log({ client })
    console.log({ storageProvider })

    console.log(`Funding generated wallets... (deployer, anyone and client)`)
    utils.lotus.sendFunds(deployer.fil.address, 10)
    utils.lotus.sendFunds(anyone.fil.address, 10)
    utils.lotus.sendFunds(client.fil.address, 10)

    await utils.defaultTxDelay()

    console.log(`DEBUG: clientIdAddress: ${utils.lotus.findIDAddressToBytes(client.fil.address)}`)

    console.log(`Deploying contracts... (market and helper)`)

    const market = await utils.deployContract(deployer, "MarketApiTest")
    const helper = await utils.deployContract(deployer, "MarketHelper")

    console.log(`Contracts deployed:`)
    console.log({ market })
    console.log({ helper })

    console.log(`Setting miner control address... market.eth.contract: ${market.fil.address}`)
    utils.lotus.setControlAddress(market.fil.address)

    console.log(`Funding Escrows... (client and provider)`)
    const amount = BigInt(10 ** 18)

    await market.eth.contract.add_balance({ data: client.fil.byteAddress }, amount, { gasLimit: 1_000_000_000, value: amount })

    await utils.defaultTxDelay()

    await market.eth.contract.add_balance({ data: storageProvider.fil.byteAddress }, amount, { gasLimit: 1_000_000_000, value: amount })

    await utils.defaultTxDelay()

    const balances = {
        client: await market.eth.contract.get_balance({ data: client.fil.byteAddress }),
        provider: await market.eth.contract.get_balance({ data: storageProvider.fil.byteAddress }),
    }
    console.log(`DEBUG:`)
    console.log({ balances: JSON.stringify(balances) })

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

    //Actual values
    const dealID = await market.eth.contract.publishedDealIds(0)
    const actualDealCommitment: MarketTypes.GetDealDataCommitmentReturnStruct = await market.eth.contract.get_deal_data_commitment(dealID)
    const actualDealClientId = await market.eth.contract.get_deal_client(dealID)
    const actualDealClient: CommonTypes.FilAddressStruct = await helper.eth.contract.get_address_from_id(actualDealClientId)
    const actualDealProviderId = await market.eth.contract.get_deal_provider(dealID)
    const actualDealProvider: CommonTypes.FilAddressStruct = await helper.eth.contract.get_address_from_id(actualDealProviderId)
    const actualDealLabel: CommonTypes.DealLabelStruct = await market.eth.contract.get_deal_label(dealID)
    const actualDealTerm: MarketTypes.GetDealTermReturnStruct = await market.eth.contract.get_deal_term(dealID)
    const actualDealTotalPrice: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_total_price(dealID)
    const actualDealClientCollateral: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_client_collateral(dealID)
    const actualDealProviderCollateral: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_provider_collateral(dealID)

    console.log(`DEBUG:`, {
        dealID,
        actualDealClient,
        actualDealClientCollateral,
        actualDealProviderCollateral,
        actualDealProvider,
        actualDealLabel,
        actualDealTerm,
        actualDealTotalPrice,
        actualDealCommitment,
        expectedDealCommitment,
    })

    //One way to compare the values (individually)
    expect(actualDealCommitment.data).to.eq(expectedDealCommitment.data)
    expect(actualDealCommitment.size).to.eq(expectedDealCommitment.size)

    //Second way to compare the values (jointly)
    expect(actualDealCommitment).to.eql(Object.values(expectedDealCommitment))
}
