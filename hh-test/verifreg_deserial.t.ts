import { ethers, network } from "hardhat"
import * as utils from "./utils"

import { VerifRegApiTest, VerifRegApiTest__factory } from "../typechain-types"
import { assert } from "console"

const DBG_LOG_ON = false

async function main() {
    const deployerPk = network.config.accounts[0]

    const provider = new ethers.providers.JsonRpcProvider(network.config.url)

    const deployer = new ethers.Wallet(deployerPk, provider)

    console.log(`\nDeploying contracts... (verifreg)\n`)

    const fact = new VerifRegApiTest__factory()

    const verifreg = await fact.connect(deployer).deploy()

    await utils.delay(15_000)

    console.log(`\nCalling: get_claims(...)\n`)

    //fil-sol issue#51 example values
    const claimObject = { provider: 33601, claim_ids: [27133] }

    const replicateFirstClaimId = (claimObject, n) => {
        const claim_ids = [...new Array(10)].map(() => claimObject.claim_ids[0])
        return { ...claimObject, claim_ids }
    }

    //fetch and compare all results with the initial request
    const resOne = await verifreg.get_claims(claimObject)
    dbgLogRes(`resOne:`, resOne)

    for (let len = 2; len < 10; len += 1) {
        const replicatedClaimObject = replicateFirstClaimId(claimObject, len)
        const resReplicated = await verifreg.get_claims(replicatedClaimObject)
        dbgLogRes(`resReplicated:::${len}:`, resReplicated)

        //check correctness
        const bigNumberKeys = ["provider", "client", "size", "term_min", "term_max", "term_start", "sector"]
        for (const repClaim of resReplicated.claims) {
            for (const bnk of bigNumberKeys) {
                assert(repClaim[bnk].eq(resOne.claims[0][bnk]), `ERR: replicated(${len}).claim.${bnk} !== resOne.claim.${bnk}!`)
            }
            assert(repClaim.data === resOne.claims[0].data, `ERR: replicated(${len}).data !== resOne.data!`)
        }
    }

    console.log(`Verifreg deserialize. test completed!`)
}
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

const dbgLogRes = (name, res) => {
    if (DBG_LOG_ON === false) return
    console.log(`\n---------> `, name)
    console.log("success_count", res.batch_info.success_count)
    console.log("fail_codes", res.batch_info.fail_codes)
    console.log("claims", res.claims)
}
