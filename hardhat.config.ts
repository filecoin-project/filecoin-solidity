import { HardhatUserConfig } from "hardhat/config"

import "@openzeppelin/hardhat-upgrades"
import "@nomicfoundation/hardhat-foundry"

import { readFileSync } from "fs"

let extractedSolcVersion: string
try {
    const tomlData = readFileSync("./foundry.toml", { encoding: "utf8", flag: "r" })

    extractedSolcVersion = tomlData.split(`solc`)[1].split("=")[1].split("\n")[0].replaceAll(" ", "").replaceAll('"', "").replaceAll("'", "")
} catch {
    console.log({ error: "Solc version in foundry.toml not set" })
    process.exit(1)
}

const config: HardhatUserConfig = {
    solidity: extractedSolcVersion,
    networks: {
        hardhat: {
            blockGasLimit: 1000000000000000,
        },
        localnet: {
            url: "http://127.0.0.1:1234/rpc/v1",
            accounts: [],
            chainId: 31415926,
            gas: 2000000000000,
        },
    },
    mocha: {
        timeout: 100000000,
    },
}

export default config
