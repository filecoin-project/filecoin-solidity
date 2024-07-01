import { MarketTypes, CommonTypes } from "../../typechain-types/contracts/v0.8/tests/market.test.sol/MarketApiTest"

export const getActualDealInfo = async (market: any, dealID: number) => {
    const dealCommitment: MarketTypes.GetDealDataCommitmentReturnStruct = await market.eth.contract.get_deal_data_commitment(dealID)
    const dealClientId = await market.eth.contract.get_deal_client(dealID)
    const dealProviderId = await market.eth.contract.get_deal_provider(dealID)
    const dealLabel: CommonTypes.DealLabelStruct = await market.eth.contract.get_deal_label(dealID)
    const dealTerm: MarketTypes.GetDealTermReturnStruct = await market.eth.contract.get_deal_term(dealID)
    const dealTotalPrice: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_total_price(dealID)
    const dealClientCollateral: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_client_collateral(dealID)
    const dealProviderCollateral: CommonTypes.BigIntStruct = await market.eth.contract.get_deal_provider_collateral(dealID)

    const dealVerified = await market.eth.contract.get_deal_verified(dealID)
    const dealActivation: MarketTypes.GetDealActivationReturnStruct = await market.eth.contract.get_deal_activation(dealID)

    return {
        dealCommitment,
        dealClientId,
        dealProviderId,
        dealLabel,
        dealTerm,
        dealTotalPrice,
        dealClientCollateral,
        dealProviderCollateral,
        dealVerified,
        dealActivation,
    }
}

export const CHECKING_DEAL_IDS = [193771, 193630]

export const EXPECTED_DEAL_INFO = {
    193771: {
        dealCommitment: { data: "0x000181e20392202059a55142771123075b29b33b79cd6b03b4c4b00f6b6b49e7d541c476fcd00c3a", size: BigInt(536870912) },
        dealClientId: BigInt(35150),
        dealProviderId: BigInt(17840),
        dealLabel: {
            data: "0x62616679626569636c7067676634356e696d6c6b7a716e6e77746466706c36646137696a7134716d6973356469656d646733733679656a366c3434",
            isString: true,
        },
        dealTerm: { start: BigInt(1589409), end: BigInt(3542400) },
        dealTotalPrice: { val: "0x", neg: false },
        dealClientCollateral: { val: "0x", neg: false },
        dealProviderCollateral: { val: "0x", neg: false },
        dealVerified: true,
        dealActivation: { activated: BigInt(1584851), terminated: BigInt(0) },
    },
    193630: {
        dealCommitment: { data: "0x000181e2039220206e4100083d6843845e8e3d2f8f785a7f1a2b5d3300d2645ffe1d99a811cbdf08", size: BigInt(34359738368) },
        dealClientId: BigInt(1206),
        dealProviderId: BigInt(95029),
        dealLabel: {
            data: "0x6d4158436735414967586a7965624f39443365764a4e4c4978354576374548506e4f56466564306d48335a6856544852506a5938",
            isString: true,
        },
        dealTerm: { start: BigInt(1647431), duration: BigInt(1468800) },
        dealTotalPrice: { val: "0x", neg: false },
        dealClientCollateral: { val: "0x", neg: false },
        dealProviderCollateral: { val: "0x", neg: false },
        dealVerified: false,
        dealActivation: { activated: BigInt(1578570), terminated: BigInt(0) },
    },
}
