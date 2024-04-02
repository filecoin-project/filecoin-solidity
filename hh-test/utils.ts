import { execSync } from "child_process"
import { newDelegatedEthAddress, newFromString } from "@glif/filecoin-address"
import { MarketTypes } from "../typechain-types/contracts/v0.8/tests/market.test.sol/MarketApiTest"
import { ethers, network } from "hardhat"

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
    sendFunds: async (filAddress: string, amount: number) => {
        // console.log({ fcn: "sendFunds", filAddress, amount })
        return execSync(`docker exec lotus lotus send ${filAddress} ${amount}`).toString()
    },
    createWalletBLS: async () => {
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
        },
        client_signature: new Uint8Array(),
    }

    const dealInfo = {
        deal,
        dealDebug: {
            total_price: {
                val: hexToBytes(((end_epoch - start_epoch) * storage_price_per_epoch).toString(16).slice(2)),
                neg: false,
            },
        },
    }

    dealID += 1

    return dealInfo
}

export const createNetworkProvider = () => {
    return new ethers.JsonRpcProvider((network.config as any).url)
}

export const defaultTxDelay = async () => {
    if (network.config.chainId == 31415926) {
        //localnet
        await delay(60_000)
    } else if (network.config.chainId == 314159) {
        //calibnet
        await delay(60_000)
    }
}

export const generate_f410_accounts = (n: number) => {
    //generates f410 type of accounts and attaches their convient information
    const accounts = []
    const provider = createNetworkProvider()
    for (let i = 0; i < n; i += 1) {
        const signer = ethers.Wallet.createRandom().connect(provider)
        const filAddress = ethAddressToFilAddress(signer.address)
        const account = {
            eth: {
                signer,
                address: signer.address,
            },
            fil: {
                address: filAddress,
                byteAddress: filAddressToBytes(filAddress),
            },
        }
        accounts.push(account)
    }
    return accounts
}

export const generate_f3_accounts = async (n: number) => {
    //generates f3 type of accounts and attaches their convient information

    const accounts = []
    for (let i = 0; i < n; i += 1) {
        const filAddr = await lotus.createWalletBLS()
        const account = {
            eth: {},
            fil: {
                address: filAddr,
                byteAddress: filAddressToBytes(filAddr),
            },
        }
        accounts.push(account)
    }
    return accounts
}

export const getStorageProvider = () => {
    //packs default miner info into a convient format
    const filAddr = "t01000" //default - created by lotus-miner in localnet

    return {
        eth: {},
        fil: {
            address: filAddr,
            byteAddress: filAddressToBytes(filAddr),
        },
    }
}

export const deployContract = async (deployer: any, name: string, params?: []) => {
    //deploys a contract and attaches all the needed info for tests
    const ContractFactory = await ethers.getContractFactory(name, deployer.eth.signer)

    let contract
    if (params == null) contract = await ContractFactory.connect(deployer.eth.signer).deploy()
    else contract = await ContractFactory.connect(deployer.eth.signer).deploy(...params)

    await contract.waitForDeployment()
    await defaultTxDelay()

    const ethAddr = await contract.getAddress()
    const filAddr = ethAddressToFilAddress(ethAddr)
    return {
        eth: {
            contract,
            address: ethAddr,
        },
        fil: {
            address: filAddr,
            byteAddress: filAddressToBytes(filAddr),
        },
    }
}
