import { ethers, upgrades, network } from "hardhat"
import { expect } from "chai"

import * as utils from "../utils"

import { MarketApiUpgradeableTest, MarketHelper } from "../../typechain-types"
import { MarketTypes, CommonTypes } from "../../typechain-types/tests/market.test.sol/MarketApiTest"

describe("Market contract - Transparent Proxy Upgrade", function () {
    it("Should publish a deal", async function () {
        const provider = new ethers.providers.JsonRpcProvider((network.config as any).url)

        console.log(`Generating accounts...`)
        const [deployer, anyone] = [ethers.Wallet.createRandom().connect(provider), ethers.Wallet.createRandom(ethers.provider).connect(provider)]

        const clientFilAddress = utils.lotus.createWalletBLS()
        const providerFilAddress = "t01000" //default - created by lotus-miner

        console.log(`Generated:`)
        console.log({
            deployer: {
                ethAddr: deployer.address,
                filAddress: utils.ethAddressToFilAddress(deployer.address),
            },
        })
        console.log({
            anyone: {
                ethAddr: anyone.address,
                filAddress: utils.ethAddressToFilAddress(anyone.address),
            },
        })
        console.log({ client: { filAddress: clientFilAddress } })
        console.log({ provider: { filAddress: providerFilAddress } })

        console.log(`Funding generated wallets... (deployer, anyone and client)`)
        utils.lotus.sendFunds(utils.ethAddressToFilAddress(deployer.address), 10)
        utils.lotus.sendFunds(utils.ethAddressToFilAddress(anyone.address), 10)
        utils.lotus.sendFunds(clientFilAddress, 10)

        //Introduce artificial delay due to Filecoin's delayed execution model
        await utils.delay(60000)

        console.log(`DEBUG: clientIdAddress: ${utils.lotus.findIDAddressToBytes(clientFilAddress)}`)

        console.log(`Deploying contracts... (market and helper)`)

        const HelperContractFactory = await ethers.getContractFactory("MarketHelper", deployer)
        const helperContract: MarketHelper = await HelperContractFactory.connect(deployer).deploy()

        console.log({ helperContract: "deployed" })

        const MarketContractFactory = await ethers.getContractFactory("MarketApiUpgradeableTest", deployer)
        const marketContract: MarketApiUpgradeableTest = (await upgrades.deployProxy(MarketContractFactory, [], {
            unsafeAllow: ["delegatecall"],
        })) as unknown as MarketApiUpgradeableTest

        console.log({ MarketContractProxy: "deployed" })

        await marketContract.deployed()
        await helperContract.deployed()

        await utils.delay(30000)

        console.log(`ADMIN: ${await upgrades.erc1967.getAdminAddress(marketContract.address)}`)

        const marketContractEthAddress = marketContract.address
        const marketContractFilAddress = utils.ethAddressToFilAddress(marketContractEthAddress)

        const helperContractEthAddress = helperContract.address
        const helperContractFilAddress = utils.ethAddressToFilAddress(helperContractEthAddress)

        console.log(`Contracts deployed:`)
        console.log({
            market: { ethAddress: marketContractEthAddress, filAddress: marketContractFilAddress },
        })
        console.log({
            helper: { ethAddress: helperContractEthAddress, filAddress: helperContractFilAddress },
        })

        console.log(`Setting miner control address... marketContract: ${marketContractFilAddress}`)
        utils.lotus.setControlAddress(marketContractFilAddress)

        console.log(`Funding Escrows... (client and provider)`)
        const amount = BigInt(10 ** 18)
        const txs = await Promise.resolve([
            await marketContract.add_balance({ data: utils.filAddressToBytes(clientFilAddress) }, amount, { gasLimit: 1_000_000_000, value: amount }),
            await marketContract.add_balance({ data: utils.filAddressToBytes(providerFilAddress) }, amount, { gasLimit: 1_000_000_000, value: amount }),
        ])
        for (const tx of txs) {
            tx.wait(2)
        }

        //Introduce artificial delay due to Filecoin's delayed execution model
        await utils.delay(50000)

        const balances = {
            client: await marketContract.get_balance({
                data: utils.filAddressToBytes(clientFilAddress),
            }),
            provider: await marketContract.get_balance({
                data: utils.filAddressToBytes(providerFilAddress),
            }),
        }
        console.log(`DEBUG:`)
        console.log({ balances: JSON.stringify(balances) })

        console.log(`Generating deal params...`)
        const deal = utils.generateDealParams(clientFilAddress, providerFilAddress)
        const serializedDealProposal = (await helperContract.serialize_deal_proposal(deal.proposal)).slice(2)
        const signedDealProposal = utils.lotus.signMessage(clientFilAddress, serializedDealProposal)

        deal.client_signature = utils.hexToBytes(signedDealProposal)

        console.log(`Publishing deal...`) //Note: Anyone can issue the publishing transaction
        const tx = await marketContract.connect(anyone).publish_storage_deals({ deals: [deal] }, { gasLimit: 1_000_000_000 })

        await tx.wait(2)

        console.log(`Deal has been published`)

        //Introduce artificial delay due to Filecoin's delayed execution model
        await utils.delay(50000)

        //Asertions

        //Expected values
        const expected = {
            dealCommitment: {
                data: ethers.utils.hexlify(Uint8Array.from([0, ...ethers.utils.arrayify(deal.proposal.piece_cid.data)])),
                size: deal.proposal.piece_size,
            },
            dealClient: deal.proposal.client,
            dealProvider: deal.proposal.provider,
            dealLabel: deal.proposal.label,
            dealTerm: { start: deal.proposal.start_epoch, end: deal.proposal.end_epoch },
            dealClientCollateral: deal.proposal.client_collateral,
            dealProviderCollateral: deal.proposal.provider_collateral,
            dealTotalPrice: deal.proposal.total_price,
        }

        //Actual values
        const getActualValues = async ({ dealNumber }) => {
            const dealID = await marketContract.publishedDealIds(dealNumber)
            const dealCommitment: MarketTypes.GetDealDataCommitmentReturnStruct = await marketContract.get_deal_data_commitment(dealID)
            const dealClientId = await marketContract.get_deal_client(dealID)
            const dealClient: CommonTypes.FilAddressStruct = await helperContract.get_address_from_id(dealClientId)
            const dealProviderId = await marketContract.get_deal_provider(dealID)
            const dealProvider: CommonTypes.FilAddressStruct = await helperContract.get_address_from_id(dealProviderId)
            const dealLabel: CommonTypes.DealLabelStruct = await marketContract.get_deal_label(dealID)
            const dealTerm: MarketTypes.GetDealTermReturnStruct = await marketContract.get_deal_term(dealID)
            const dealTotalPrice: CommonTypes.BigIntStruct = await marketContract.get_deal_total_price(dealID)
            const dealClientCollateral: CommonTypes.BigIntStruct = await marketContract.get_deal_client_collateral(dealID)
            const dealProviderCollateral: CommonTypes.BigIntStruct = await marketContract.get_deal_provider_collateral(dealID)

            const returnValues = {
                dealID,
                dealCommitment,
                dealClientId,
                dealClient,
                dealProviderId,
                dealProvider,
                dealLabel,
                dealTerm,
                dealTotalPrice,
                dealClientCollateral,
                dealProviderCollateral,
            }

            console.log(`DEBUG: ${JSON.stringify(returnValues)}`)

            return returnValues
        }

        const compareDealInformation = ({ expected, actual }) => {
            expect(actual.dealCommitment.data).to.eq(expected.dealCommitment.data)
            expect(actual.dealCommitment.size.eq(ethers.BigNumber.from(expected.dealCommitment.size))).to.eq(true)

            expect(actual.dealTerm.start.eq(ethers.BigNumber.from(expected.dealTerm.start))).to.eq(true)
            expect(actual.dealTerm.end.eq(ethers.BigNumber.from(expected.dealTerm.end).sub(ethers.BigNumber.from(expected.dealTerm.start)))).to.eq(true)

            expect(actual.dealClientCollateral.val).to.eq("0x" + Buffer.from(expected.dealClientCollateral.val).toString("hex"))
            expect(actual.dealClientCollateral.neg).to.eq(expected.dealClientCollateral.neg)

            expect(actual.dealProvider.data).to.eq("0x" + Buffer.from(expected.dealProvider.data).toString("hex"))

            expect(actual.dealProviderCollateral.val).to.eq("0x" + Buffer.from(expected.dealProviderCollateral.val).toString("hex"))
            expect(actual.dealProviderCollateral.neg).to.eq(expected.dealProviderCollateral.neg)

            expect(actual.dealTotalPrice.val).to.eq("0x" + Buffer.from(expected.dealTotalPrice.val).toString("hex"))
            expect(actual.dealTotalPrice.neg).to.eq(expected.dealTotalPrice.neg)
        }

        const actual = await getActualValues({ dealNumber: 0 })
        compareDealInformation({ expected, actual })

        const MarketContractFactoryV2 = await ethers.getContractFactory("MarketApiUpgradeableV2Test", deployer)
        await upgrades.upgradeProxy(marketContract.address, MarketContractFactoryV2, {
            unsafeAllow: ["delegatecall"],
        })

        const actualUpgraded = await getActualValues({ dealNumber: 0 })
        compareDealInformation({ expected, actual: actualUpgraded })
    })
})
