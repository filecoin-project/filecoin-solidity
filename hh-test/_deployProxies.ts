import { ethers } from "hardhat"
import { writeFileSync } from "fs"
import * as utils from "./utils"
import { CommonTypes, DataCapTypes } from "../typechain-types/contracts/v0.8/tests/datacap.test.sol/DataCapApiTest"

import "dotenv/config"
import { execSync } from "child_process"

const main = async () => {
    const [deployer, userWithDataCapAddr] = utils.generate_and_fund_f410_accounts(2, 100)
    const [verifier, verifier2] = await utils.generate_f3_accounts(2)

    utils.lotus.sendFunds(verifier.fil.address, 10)
    utils.lotus.sendFunds(verifier2.fil.address, 10)
    await utils.defaultTxDelay()

    const proxyFact = await utils.deployContract(deployer, "_BasicProxyFactory")

    const proxyCount = await proxyFact.eth.contract.getProxyCount()

    const verifRegProxyAddr = await proxyFact.eth.contract.verifRegProxy()
    const dataCapProxyAddr = await proxyFact.eth.contract.dataCapProxy()

    writeFileSync("/var/lib/fil-sol/lib-dev/dev-env/.internal/proxyFactory.addr", proxyFact.eth.address)
    writeFileSync("/var/lib/fil-sol/lib-dev/dev-env/.internal/verifRegProxy.addr", verifRegProxyAddr)
    writeFileSync("/var/lib/fil-sol/lib-dev/dev-env/.internal/dataCapProxy.addr", dataCapProxyAddr)
    writeFileSync("/var/lib/fil-sol/lib-dev/dev-env/.internal/userWithDataCap.addr", userWithDataCapAddr.fil.address)

    await utils.lotus.restart({ LOTUS_FEVM_ENABLEETHRPC: false })

    execSync(`echo "RPC_RESTARTED" >> /var/lib/fil-sol/log.txt`)

    utils.lotus.registerVerifier(utils.ethAddressToFilAddress(verifRegProxyAddr), 16000000)
    utils.lotus.registerVerifier(verifier.fil.address, 16000000)
    utils.lotus.registerVerifier(verifier2.fil.address, 16000000)
    utils.lotus.grantDatacap(verifier.fil.address, utils.ethAddressToFilAddress(dataCapProxyAddr), 1000)
    // utils.lotus.grantDatacap(verifier2.fil.address, userWithDataCapAddr.fil.address, 1000)

    console.log("RUN done!")

    utils.lotus.kill()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
