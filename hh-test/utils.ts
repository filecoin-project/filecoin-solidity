import { execSync } from "child_process"
import { newDelegatedEthAddress, newFromString } from "@glif/filecoin-address"
import { CommonTypes, MarketTypes } from "../typechain-types/contracts/v0.8/tests/market.test.sol/MarketApiTest"
import { ethers, network } from "hardhat"

let DEBUG_ON = false
export const setDebugMode = (newVal) => (DEBUG_ON = newVal)

const PATH_EXPORTS = `export LOTUS_PATH=~/.lotus-local-net && export LOTUS_MINER_PATH=~/.lotus-miner-local-net && \
export LOTUS_SKIP_GENESIS_CHECK=_yes_ && export CGO_CFLAGS_ALLOW='-D__BLST_PORTABLE__' && \
export CGO_CFLAGS='-D__BLST_PORTABLE__' `

const PREFIX_CMD = `docker exec pensive_kowalevski  /bin/bash -c "${PATH_EXPORTS} && /go/lotus-local-net/`

const CID = require("cids")

export const paddForHex = (hex: string) => {
    //assumes no leading `0x`
    return hex.length % 2 == 1 ? `0${hex}` : hex
}

export const hexToBytes = (hex: string) => {
    //assumes 0x..{even number of nibbles}...
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
        return execSync(`${PREFIX_CMD}lotus-miner actor control set --really-do-it ${filAddress}"`).toString()
    },
    signMessage: (filAddress: string, message: string) => {
        const signatureCmdOutput = execSync(`${PREFIX_CMD}lotus wallet sign ${filAddress} ${message}"`).toString()
        return signatureCmdOutput.replace("\n", "")
    },
    sendFunds: (filAddress: string, amount: number) => {
        return execSync(`${PREFIX_CMD}lotus send ${filAddress} ${amount}"`).toString()
    },
    createWalletBLS: () => {
        return execSync(`${PREFIX_CMD}lotus wallet new bls"`).toString().replace("\n", "")
    },
    findIDAddressToBytes: (filAddress: string) => {
        const idAddress = execSync(`${PREFIX_CMD}lotus state lookup ${filAddress}"`).toString().replace("\n", "")
        const temp = paddForHex(BigInt(`${idAddress.slice(2, idAddress.length)}`).toString(16))
        console.log({ idAddress, temp })
        return hexToBytes("0x" + temp)
    },
    registerNotary: (filAddress: string, amount: number) => {
        const rootKey1 = "t3vxtpol2vygxep7xin2n2mr7zax3dschn27ayk4x6rn54bf4qmsxp24mcm7vzngjwysrv2g4sbkshj7yljukq"
        // const rootKey2 = "t3v2x5wvxwehtmayz5cqiuxdkezcj3aogkhoq7kfukuzp5mlcgauewqlco6inwgrxr3xyz7gnzh3u2hgxjjy4q"
        const cmd = `${PREFIX_CMD}lotus-shed verifreg add-verifier ${rootKey1} ${filAddress} ${amount}`
        console.log({ registerNotary: cmd })
        return execSync(cmd).toString().replace("\n", "")
        //lotus msig approve  --from=t3vmxr3jfjpqckhy7zn4nmp3tqk2wla4hwbcwdqxraggehw7k3huosljt3bmhvvf5jsxozbpz6stbuyb4r57ea f080 1 t0101 f06 0 2 8256040a5a321fa1d6279aa337e34d38e97203f04a6a4db1420064
        //TODO:parsing from: lotus msig inspect f080
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
                val: `0x${paddForHex(((end_epoch - start_epoch) * storage_price_per_epoch).toString(16))}`,
                neg: false,
            },
            start_epoch,
            end_epoch,
        },
    }

    dealID += 1

    return dealInfo
}

export const createNetworkProvider = () => {
    const provider = new ethers.JsonRpcProvider((network.config as any).url)
    return provider
}

export const defaultTxDelay = async () => {
    if (network.config.chainId == 31415926) {
        //localnet
        await delay(4_500)
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

export const generate_and_fund_f410_accounts = (n: number, amount: number) => {
    //generates f410 type of accounts and funds them

    const accounts = generate_f410_accounts(n)

    for (const acc of accounts) {
        lotus.sendFunds(acc.fil.address, amount)
    }

    return accounts
}

export const generate_f3_accounts = async (n: number) => {
    //generates f3 type of accounts and attaches their convient information

    const accounts = []
    for (let i = 0; i < n; i += 1) {
        const filAddr = lotus.createWalletBLS()
        const account = {
            eth: {},
            fil: {
                address: filAddr,
                byteAddress: filAddressToBytes(filAddr),
                // idAddress: lotus.findIDAddressToBytes(filAddr),
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
            idAddress: lotus.findIDAddressToBytes(filAddr),
        },
    }
}

export const performGeneralSetup = async () => {
    //general setup present in most of the tests
    if (DEBUG_ON) {
        console.log(`performGeneralSetup() called`)
    }
    const [deployer, anyone] = generate_f410_accounts(2)
    const [client] = await generate_f3_accounts(1)
    const storageProvider = getStorageProvider()

    if (DEBUG_ON) {
        console.log(`Generated:`, { deployer, anyone, client, storageProvider })
        console.log(`Funding generated wallets... (deployer, anyone and client)`)
    }

    lotus.sendFunds(deployer.fil.address, 10)
    lotus.sendFunds(anyone.fil.address, 10)
    lotus.sendFunds(client.fil.address, 10)

    await defaultTxDelay()

    //note: can happen only after funding and not in `generate_f3`
    client.fil.idAddress = lotus.findIDAddressToBytes(client.fil.address)

    if (DEBUG_ON) {
        console.log(`Funding done.`)
    }

    return { deployer, anyone, client, storageProvider }
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
            idAddress: lotus.findIDAddressToBytes(filAddr),
        },
    }
}

export const attachToContract = async (account: any, name: string, contractAddress: string) => {
    const ContractFactory = await ethers.getContractFactory(name, account.eth.signer)
    const contract = ContractFactory.attach(contractAddress).connect(account.eth.signer)

    return contract
}

export const idAddressToBigInt = (idAddress: Uint8Array) => {
    const result = BigInt(bytesToHex(idAddress).replace("0x00", "0x"))
    console.log({ idAddressToBigInt: "called", idAddress, result })
    return result
}

export const bigIntStructWithStringFormat = (bigint: CommonTypes.BigIntStruct) => {
    return { val: bytesToHex(bigint.val as Uint8Array), neg: bigint.neg }
}

export const bigIntToHexString = (bigint: BigInt) => {
    return `0x${paddForHex(bigint.toString(16))}`
}
