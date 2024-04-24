import { HardhatUserConfig } from "hardhat/config"

import "@typechain/hardhat"
import "@openzeppelin/hardhat-upgrades"
import "@nomicfoundation/hardhat-foundry"

import "@nomicfoundation/hardhat-ethers"
import "hardhat-contract-sizer"

import { readFileSync } from "fs"

import "dotenv/config"

let extractedSolcVersion: string
try {
    const tomlData = readFileSync("./foundry.toml", { encoding: "utf8", flag: "r" })

    extractedSolcVersion = tomlData.split(`solc`)[1].split("=")[1].split("\n")[0].replaceAll(" ", "").replaceAll('"', "").replaceAll("'", "")
} catch {
    console.log({ error: "Solc version in foundry.toml not set (Hardhat needs to be run from projects root)" })
    process.exit(1)
}

const HH_NETWORK = process.env.HH_NETWORK != undefined ? process.env.HH_NETWORK : "localnet"
const SUPPORTED_NETWORKS = {
    localnet: {
        url: "http://127.0.0.1:1234/rpc/v1",
        chainId: 31415926,
        gas: 1_000_000_000,
        blockGasLimit: 1_000_000_000,
    },
    calibnet: {
        url: "https://api.calibration.node.glif.io/rpc/v1",
        chainId: 314159,
        accounts: [process.env.ETH_PK],
    },
}

if (HH_NETWORK === undefined || SUPPORTED_NETWORKS[HH_NETWORK] == null) {
    console.log({ error: `HH_NETWORK env var (val:${HH_NETWORK}) not supported! (Must be: ${Object.keys(SUPPORTED_NETWORKS).join(" | ")})` })
    process.exit(1)
}

const config: HardhatUserConfig = {
    solidity: {
        version: extractedSolcVersion,
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    defaultNetwork: HH_NETWORK,
    networks: SUPPORTED_NETWORKS,
    mocha: {
        timeout: 1000000000,
    },
    paths: {
        tests: `./hh-test/${HH_NETWORK}/e2e`,
    },
}

export default config
