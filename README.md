# Filecoin Solidity

---

Originally authored by Zondax. Learn more at [zondax.ch](https://www.zondax.ch).
Protocol Labs are now the owners of this library, and will mantain it moving forward.

---

## Notice

This is software is available under Apache 2.0 License. Use of this library implies your acceptance of these terms and conditions

Things to keep in mind, while using this library:

-   There are implicit invariants these contracts expect to hold.
-   You should exhaustively read each contract you plan to use, top to bottom.
-   **You can easily “shoot yourself in the foot” if you’re not careful with how you use the library.**

---

## Disclaimer :warning:

The libraries have been developed under the following set of assumptions.

Take a look at them [here](https://docs.zondax.ch/fevm/filecoin-solidity/introduction/assumptions).

---

## Introduction

### Filecoin Virtual Machine (FVM)

Filecoin today lacks general programmability. As a result, it is not possible to deploy user-defined behaviour, or "smart contracts", to the blockchain. The goal of the FVM project is to add general programmability to the Filecoin blockchain.
They predict this will unleash a proliferation of new services and tools that can be built and deployed to the Filecoin network, without requiring network upgrades, involvement from core implementation maintainers, changes in the embedded actors, or spec alterations.

## Filecoin Solidity

It is a set of Solidity libraries that allow Solidity smart contracts to seamlessly call methods of Filecoin built-in actors. They do cross-platform calls to the real Filecoin built-in actors. A set of mock libraries are located too. They respond to specific scenarios based on the received parameters instead of doing real calls.

### Features

#### Libraries to interact with built-in actors

Querying an operating on the storage market, miner actors, verified registry for FIL+ automation, and more.

#### OpenZeppelin-like utilities specific to Filecoin

For developer convenience.

#### Filecoin data types

Sectors, deals, partitions, deadlines, and more.

#### Access to system features

via Filecoin precompiles

### How to use it

In order to use these APIs in your project, you will need to import them on your own contract.
As they are embeddable libraries, they don't need to be present on the chain first. You can just import the library you desire and call its methods.

#### Local files

You will need to copy these files to a folder inside your project. Let's name it `libs`. In your smart contract, copy and paste these lines.

```solidity
import { MarketAPI } from "./libs/MarketAPI.sol";
import { CommonTypes } from "./libs/types/CommonTypes.sol";
import { MarketTypes } from "./libs/types/MarketTypes.sol";
```

#### NPM Package

A better approach to import these libs is using the NPM package created for this. [:link:](https://www.npmjs.com/package/@zondax/filecoin-solidity).
Run on your project in order to add this package.

```yarn
yarn add @zondax/filecoin-solidity
```

In your smart contract, copy and paste these lines.

```solidity
import { MarketAPI } from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import { CommonTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import { MarketTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import { BigInt } from "@zondax/filecoin-solidity/contracts/v0.8/cbor/BigIntCbor.sol";
```

### Supported networks

The following table contains information about the versions of filecoin network on which the `filecoin-solidity` library has been tested on.

|                                              FVM version                                              |                                                         Builtin actors                                                          |        Pass        |
| :---------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------: | :----------------: |
| [fvm@v3.0.0-alpha.21](https://github.com/filecoin-project/ref-fvm/releases/tag/fvm%40v3.0.0-alpha.21) | [builtin_actors@dev/20230206-pre-rc.6](https://github.com/filecoin-project/builtin-actors/releases/tag/dev%2F20230206-pre-rc.6) | :white_check_mark: |

## Complementary lectures

### Introduction to Filecoin [:link:](https://docs.filecoin.io/intro/intro-to-filecoin/what-is-filecoin/)

Important explainers & concepts on Filecoin storage and retrieval markets, FVM as part of Filecoin and Lotus nodes that power the Filecoin network.

### Filecoin 101: conceptual read [:link:](https://hackernoon.com/the-filecoin-virtual-machine-everything-you-need-to-know)

If you’re starting totally new, we got you! Here’s a 101 conceptual read on understanding FVM from scratch.

### Past Hackathons

#### FVM Space Warp ETHGlobal Cheat Sheet [:link:](https://github.com/filecoin-project/community/discussions/585)

### Community Discussions [:link:](https://github.com/filecoin-project/community/discussions)

Find nice articles with rich and valuable content about different topics related to Filecoin network.

## Looking for the complete documentation? :books::books:

Filecoin solidity documentation: [Let's go to docs web](https://docs.filecoin.io/smart-contracts/developing-contracts/solidity-libraries/) :arrow_upper_right:

## Getting Started

Requirements / Steps are performed on MacOS.

### Requirements:

-   **Foundry** [[Official Docs]](https://book.getfoundry.sh/getting-started/installation):

    `curl -L https://foundry.paradigm.xyz | bash`

-   **Rust** [[Official Docs]](https://doc.rust-lang.org/book/ch01-01-installation.html):

    `curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh`

-   **Yarn**[[Official Docs]](https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable):

    `npm install --global yarn`

-   **CMake** [[Official Docs]](https://cmake.org/download/):

    -   [MacOS] Install GUI: [v3.7.0](https://github.com/Kitware/CMake/releases/download/v3.27.0/cmake-3.27.0-macos-universal.dmg)
    -   Add it to the Application folder
    -   Open terminal and run:

        ` sudo "/Applications/CMake.app/Contents/bin/cmake-gui" --install`

### Setup process:

-   Clone the repo with the `--recursive` flag

    ```
    git clone https://github.com/MVPWorkshop/filecoin-solidity --recursive
    ```

-   Run: `cd filecoin-solidity`
-   Install Solc:

    -   MacOS:
        `make install_solc_mac`
    -   Linux:
        `make install_solc_linux`

-   Run: `make`

### Workflow

-   Compiling / testing contracts:

    `forge <build/test>`

-   Running all of the integration tests:

    `make test_integration`

-   Running individual integration tests:
    -   see [Makefile](./Makefile) for a complete list
