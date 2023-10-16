import { execSync } from "child_process"
import { newActorAddress, newDelegatedEthAddress, newFromString } from "@glif/filecoin-address"
import { MarketTypes } from "../typechain-types/tests/market.test.sol/MarketApiTest"
import { ethers } from "hardhat"

const CID = require("cids")

export const hexToBytes = (hex: string) => {
    var bytes = []

    for (var c = 0; c < hex.length; c += 2) {
        bytes.push(parseInt(hex.substr(c, 2), 16))
    }

    return Uint8Array.from(bytes)
}

export const bytesToHex = (bytes: Uint8Array) => {
    return "0x" + Buffer.from(bytes).toString("hex")
}

export const delay = (delayInms: number) => {
    return new Promise((resolve) => setTimeout(resolve, delayInms))
}

export const cidToBytes = (cid: string) => {
    const cidHexRaw = new CID(cid).toString("base16").substring(1)
    return hexToBytes(cidHexRaw)
}

export const filAddressToBytes = (addr: string) => {
    return newFromString(addr).bytes
}

export const ethAddressToFilAddress = (ethAddr: string) => {
    return "t" + newDelegatedEthAddress(ethAddr).toString().slice(1)
}

export const utf8Encode = (payload: string) => {
    const utf8EncodeText = new TextEncoder()

    return utf8EncodeText.encode(payload)
}

export const lotus = {
    setControlAddress: (filAddress: string) => {
        return execSync(`docker exec lotus-miner lotus-miner actor control set --really-do-it ${filAddress}`).toString()
    },
    signMessage: (filAddress: string, message: string) => {
        const signatureCmdOutput = execSync(`docker exec lotus lotus wallet sign ${filAddress} ${message}`).toString()
        return signatureCmdOutput.replace("\n", "")
    },
    sendFunds: (filAddress: string, amount: number) => {
        return execSync(`docker exec lotus lotus send ${filAddress} ${amount}`).toString()
    },
    createWalletBLS: () => {
        return execSync(`docker exec lotus lotus wallet new bls`).toString().replace("\n", "")
    },
    findIDAddressToBytes: (filAddress: string) => {
        const idAddress = execSync(`docker exec lotus lotus state lookup ${filAddress}`).toString().replace("\n", "")
        return newFromString(idAddress).bytes
    },
}

let dealID = 0
export const DEAL_INFO = [
    { pieceCid: "baga6ea4seaqn7y7fwlhlshrysd2j443pyi6knof2c5qp533co2mqj5rzbq7t2pi", label: "mAXCg5AIgw4oywPmiPRxJLioYxMdIkKmaJ4FFumCvS/GC4gEzGng" },
]

export const generateDealParams = (clientFilAddress: string, providerFilAddress: string) => {
    //TODO: randomize some parameters

    const start_epoch = BigInt(10000)
    const end_epoch = BigInt(10000 + (545150 - 25245))
    const storage_price_per_epoch = BigInt(1)

    const deal: MarketTypes.ClientDealProposalStruct = {
        proposal: {
            piece_cid: {
                data: cidToBytes(DEAL_INFO[dealID].pieceCid),
            },
            piece_size: BigInt(1024), //has to be power of 2 and <= 2048
            verified_deal: false,
            client: {
                data: filAddressToBytes(clientFilAddress),
            },
            provider: {
                data: filAddressToBytes(providerFilAddress),
            },
            label: {
                data: utf8Encode(DEAL_INFO[dealID].label),
                isString: true,
            },
            start_epoch,
            end_epoch,
            storage_price_per_epoch: {
                val: hexToBytes(storage_price_per_epoch.toString(16)),
                neg: false,
            },
            provider_collateral: {
                val: hexToBytes((1_000_000).toString(16)),
                neg: false,
            },
            client_collateral: {
                val: hexToBytes((1_000_000).toString(16)),
                neg: false,
            },
            total_price: {
                val: hexToBytes(
                    ethers.BigNumber.from((end_epoch - start_epoch) * storage_price_per_epoch)
                        .toHexString()
                        .slice(2)
                ),
                neg: false,
            },
        },
        client_signature: {},
    }

    dealID += 1

    return deal
}
