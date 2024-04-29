import { execSync, exec } from "child_process"
import { newDelegatedEthAddress, newFromString } from "@glif/filecoin-address"
import { CommonTypes, MarketTypes } from "../typechain-types/contracts/v0.8/tests/market.test.sol/MarketApiTest"
import { ethers, network } from "hardhat"
import { FilecoinClient, FilecoinSigner } from "@blitslabs/filecoin-js-signer"

import * as rlp from "rlp"
import * as keccak from "keccak"

import "dotenv/config"
import { writeFileSync } from "fs"

const CID = require("cids")

const DEBUG_ON = false //process.env.DEBUG_ON == undefined ? false : true

const SCRIPTS_DIR = `/var/lib/fil-sol/lib-dev/dev-env`

const PREFIX_CMD = `/bin/bash -c "`

export const paddForHex = (hex: string) => {
    //assumes no leading `0x`
    return hex.length % 2 == 1 ? `0${hex}` : hex
}

export const hexToBytes = (hex: string) => {
    //assumes 0x..{even number of nibbles}...
    const bytes = []

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
        return hexToBytes("0x" + temp)
    },
    findIDAddressToBigInt: (filAddress: string) => {
        const raw = execSync(`${PREFIX_CMD}lotus state lookup ${filAddress}"`).toString().replace("\n", "")
        return BigInt(raw.slice(2, raw.length))
    },
    restart: async (params: { LOTUS_FEVM_ENABLEETHRPC: boolean }) => {
        const exportEnvVar = `export LOTUS_FEVM_ENABLEETHRPC=${params.LOTUS_FEVM_ENABLEETHRPC}`
        const scriptRun = `${SCRIPTS_DIR}/2_restart-localnet.sh &`

        const cmd = `${PREFIX_CMD}${exportEnvVar} && ${scriptRun}"`

        exec(cmd).toString().replace("\n", "")

        await delay(90_000)
    },
    kill: () => {
        const scriptRun = `${SCRIPTS_DIR}/4_kill-lotus-ps.sh &`

        const cmd = `${PREFIX_CMD} ${scriptRun}"`

        return execSync(cmd).toString().replace("\n", "")
    },
    registerVerifier: (filAddress: string, amount: number) => {
        // console.log("registerVerifier", filAddress, amount)
        const rootKey1 = _getVerifier1RootKey()
        const cmd = `${PREFIX_CMD}lotus-shed verifreg add-verifier ${rootKey1} ${filAddress} ${amount}"`
        return execSync(cmd).toString().replace("\n", "")
    },
    grantDatacap: (notaryAddress: string, filAddress: string, amount: number) => {
        // console.log("grantDatacap", notaryAddress, filAddress, amount)
        const cmd = `${PREFIX_CMD}lotus filplus grant-datacap --from=${notaryAddress} ${filAddress} ${amount}"`
        return execSync(cmd).toString().replace("\n", "")
    },
    changeMinerOwner: (newBeneficiary: string) => {
        // const preCmd = `${PREFIX_CMD}lotus wallet set-default ...`
        //lotus-miner actor confirm-change-beneficiary  --really-do-it --new-beneficiary
        const cmd = `${PREFIX_CMD}lotus-miner actor propose-change-beneficiary --really-do-it --overwrite-pending-change ${newBeneficiary} 1 1 "`
        return execSync(cmd).toString().replace("\n", "")
    },
    evmInvoke: (contractFilAddress: string, payload: string) => {
        const payloadWithout0x = payload.replace(`0x`, ``)
        const cmd = `${PREFIX_CMD}lotus evm invoke ${contractFilAddress} ${payloadWithout0x}"`
        return execSync(cmd).toString().replace("\n", "")
    },
    importDefaultWallets: () => {
        const keyFilename = "tmp-000001.keygen"
        try {
            //note: try/catch because they are maybe already imported which will cause failure

            writeFileSync(keyFilename, process.env.F3_PK)
            _execute(`lotus wallet import ${keyFilename}`)
        } catch (err) {
            // console.log("ERR (importDefaultWallets):", err)
        }
        _execute(`rm -rf ${keyFilename}`)

        return { fil: { address: process.env.F3_ADDR, idAddress: BigInt(process.env.F3_ID) } }
    },
}

const _execute = (cmd: string, options?: any) => {
    const _options = options == null ? { stdio: [] } : options
    return execSync(`${PREFIX_CMD} ${cmd}"`, _options).toString()
}

const _getVerifier1RootKey = () => {
    return execSync("cat /var/lib/fil-sol/lib-dev/dev-env/.internal/verifier1.txt").toString().replace("\n", "")
}

export const getProxyFactory = async (account) => {
    const addr = execSync("cat /var/lib/fil-sol/lib-dev/dev-env/.internal/proxyFactory.addr").toString().replace("\n", "")

    const pFF = await ethers.getContractFactory("_BasicProxyFactory")

    const pff = pFF.attach(addr).connect(account.eth.signer)

    return pff
}
export const upgradeToDataCapProxy = async (account, contractFactory, contractAddress: string) => {
    const pff = await getProxyFactory(account)

    const pAddr = await pff.dataCapProxy()

    const pF = await ethers.getContractFactory("_BasicProxy")
    const pf = pF.attach(pAddr).connect(account.eth.signer)

    await pf.upgradeDelegate(contractAddress)
    await defaultTxDelay()

    const proxiedContract = contractFactory.attach(await pf.getAddress()).connect(account.eth.signer)

    return proxiedContract
}

export const upgradeToVerifRegProxy = async (account, contractFactory, contractAddress: string) => {
    const pff = await getProxyFactory(account)

    const pAddr = await pff.verifRegProxy()

    const pF = await ethers.getContractFactory("_BasicProxy")
    const pf = pF.attach(pAddr).connect(account.eth.signer)

    await pf.upgradeDelegate(contractAddress)
    await defaultTxDelay()

    const proxiedContract = contractFactory.attach(await pf.getAddress()).connect(account.eth.signer)

    return proxiedContract
}

export const upgradeToFirstAvailableProxy = async (account, contractFactory, contractAddress: string) => {
    const pff = await getProxyFactory(account)

    const [pAddr, pID] = await pff.getFirstAvailableProxy()

    await pff.occupyProxy(pID)

    const pF = await ethers.getContractFactory("_BasicProxy")

    const pf = pF.attach(pAddr).connect(account.eth.signer)
    await pf.upgradeDelegate(contractAddress)
    await defaultTxDelay()
    await defaultTxDelay()

    const proxiedContract = contractFactory.attach(await pf.getAddress()).connect(account.eth.signer)

    return proxiedContract
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
    if (network.name === "localnet") {
        await delay(10_000)
    } else if (network.name === "calibnet") {
        await delay(60_000)
    }
}

export const generate_f410_accounts = (n: number) => {
    //generates f410 type of accounts and attaches their convient information

    const accounts = []
    const provider = createNetworkProvider()
    for (let i = 0; i < n; i += 1) {
        const signer = ethers.Wallet.createRandom().connect(provider)
        const filAddr = ethAddressToFilAddress(signer.address)
        const account = {
            eth: {
                signer,
                address: signer.address,
            },
            fil: {
                address: filAddr,
                byteAddress: filAddressToBytes(filAddr),
                idAddress: () => lotus.findIDAddressToBytes(filAddr),
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

export const generate_and_fund_fixed_f410_accounts = (amount: number) => {
    //note: hardhat localhost created
    const privateKeys = [
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
        "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
        "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
        "0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0",
    ]
    const accounts = []
    const provider = createNetworkProvider()
    for (const pk of privateKeys) {
        const signer = new ethers.Wallet(pk).connect(provider)
        const filAddr = ethAddressToFilAddress(signer.address)

        const account = {
            eth: {
                signer,
                address: signer.address,
            },
            fil: {
                address: filAddr,
                byteAddress: filAddressToBytes(filAddr),
                idAddress: () => lotus.findIDAddressToBytes(filAddr),
            },
        }
        lotus.sendFunds(account.fil.address, amount)

        accounts.push(account)
    }

    return accounts
}

export const generate_f3_accounts = async (n: number, amount?: number) => {
    //generates f3 type of accounts and attaches their convient information

    const accounts = []
    for (let i = 0; i < n; i += 1) {
        const filAddr = lotus.createWalletBLS()
        const account = {
            eth: {},
            fil: {
                address: filAddr,
                byteAddress: filAddressToBytes(filAddr),
                idAddress: () => lotus.findIDAddressToBytes(filAddr),
            },
        }
        if (amount > 0) lotus.sendFunds(account.fil.address, amount)
        accounts.push(account)
    }
    return accounts
}

export const getStorageProvider = () => {
    //packs default miner info into a convient format

    const filAddr = "t01000" //default - created by lotus-miner in localnet
    const idAddress = () => lotus.findIDAddressToBytes(filAddr)
    return {
        eth: {},
        fil: {
            address: filAddr,
            byteAddress: filAddressToBytes(filAddr),
            idAddress,
            id: BigInt(`0x${Buffer.from(idAddress()).toString("hex")}`), // actor id
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

    await defaultTxDelay()

    lotus.sendFunds(client.fil.address, 10)
    lotus.sendFunds(deployer.fil.address, 10)
    lotus.sendFunds(anyone.fil.address, 10)

    await defaultTxDelay()

    if (DEBUG_ON) {
        console.log(`Funding done.`)
    }

    return { deployer, anyone, client, storageProvider }
}

export const performGeneralSetupOnCalibnet = async (addExtraAccounts?: boolean) => {
    const master = new ethers.Wallet(process.env.ETH_PK, createNetworkProvider())

    const deployer = { eth: { signer: master, address: await master.getAddress() }, fil: {} }

    const extraAccounts = []
    if (addExtraAccounts) {
        const [deployer, anyone] = generate_f410_accounts(2)
        const [client] = await generate_f3_accounts(1)

        const deployerAmount = BigInt(10) * BigInt(10 ** 18)
        const anyoneAmount = BigInt(1) * BigInt(10 ** 18)

        const filecoin_signer = new FilecoinSigner()

        const clientSignMessage = async (message: string) => filecoin_signer.utils.signMessage(message, process.env.F3_PK)

        await master.sendTransaction({
            to: deployer.eth.address,
            value: deployerAmount,
        })
        await defaultTxDelay()

        await master.sendTransaction({
            to: anyone.eth.address,
            value: anyoneAmount,
        })
        await defaultTxDelay()

        extraAccounts.push(deployer)
        extraAccounts.push(anyone)
    }

    return { master, deployer, extraAccounts }
}

export const deployContract = async (deployer: any, name: string, params?: { constructorParams?: [] }) => {
    //deploys a contract and attaches all the needed info for tests

    const ContractFactory = await ethers.getContractFactory(name, deployer.eth.signer)

    if (DEBUG_ON) console.log(`Contract: ${name} pre-deploy ...`)

    if (DEBUG_ON) console.log("deployer balance:", await deployer.eth.signer.provider.getBalance(deployer.eth.address))

    let contract
    if (params == null || params.constructorParams == null) contract = await ContractFactory.connect(deployer.eth.signer).deploy({ gasLimit: 10000000000 })
    else contract = await ContractFactory.connect(deployer.eth.signer).deploy(...params.constructorParams)

    if (DEBUG_ON) console.log(`Contract: ${name} deployed.`)

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
            idAddress: () => lotus.findIDAddressToBytes(filAddr),
        },
    }
}

export const attachToContract = async (account: any, name: string, contractAddress: string) => {
    const ContractFactory = await ethers.getContractFactory(name, account.eth.signer)
    const contract = ContractFactory.attach(contractAddress).connect(account.eth.signer)

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
            idAddress: () => lotus.findIDAddressToBytes(filAddr),
        },
    }
}

export const idAddressToBigInt = (idAddress: Uint8Array) => {
    const result = BigInt(bytesToHex(idAddress).replace("0x00", "0x"))
    return result
}

export const bigIntStructWithStringFormat = (bigint: CommonTypes.BigIntStruct) => {
    return { val: bytesToHex(bigint.val as Uint8Array), neg: bigint.neg }
}

export const bigIntToHexString = (bigint: BigInt) => {
    return `0x${paddForHex(bigint.toString(16))}`
}

export const computeDeploymentAddress = (sender: string, nonce = 0x00) => {
    const input_arr = [sender, nonce]
    const rlp_encoded = Buffer.from(rlp.encode(input_arr))

    const contract_address_long = keccak("keccak256").update(rlp_encoded).digest("hex")

    const contract_address = `0x${contract_address_long.substring(24)}` //Trim the first 24 chars

    return ethers.getAddress(contract_address)
}

export const getDefaultDeployer = async () => {
    //note: hardhat localhost created
    const PK = "0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0"
    const provider = createNetworkProvider()
    const signer = new ethers.Wallet(PK).connect(provider)
    const filAddr = ethAddressToFilAddress(signer.address)

    const deployer = {
        eth: {
            signer,
            address: signer.address,
        },
        fil: {
            address: filAddr,
            byteAddress: filAddressToBytes(filAddr),
            idAddress: () => lotus.findIDAddressToBytes(filAddr),
        },
    }

    const currentBalance = await deployer.eth.signer.provider.getBalance(deployer.eth.address)

    if (currentBalance == BigInt(0)) {
        lotus.sendFunds(deployer.fil.address, 100)
        await defaultTxDelay()
    }

    return deployer
}
