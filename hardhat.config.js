require("@nomicfoundation/hardhat-foundry")

const fs = require("fs")

let extractedSolcVersion
try {
    const tomlData = fs.readFileSync("./foundry.toml", { encoding: "utf8", flag: "r" })

    extractedSolcVersion = tomlData.split(`solc`)[1].split("=")[1].split("\n")[0].replaceAll(" ", "").replaceAll('"', "").replaceAll("'", "")

    console.log({ extractedSolcVersion })
} catch {
    console.log({ error: "Solc version in foundry.toml not set" })
    process.exit(1)
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: extractedSolcVersion,
}
