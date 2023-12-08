# Filecoin Solidity

---

[Protocol Labs](https://protocol.ai/) are now the owners of this library, and will mantain it moving forward.

Originally authored by [Zondax](https://www.zondax.ch).

---

## Notice

This software is dual-licensed under the [MIT License](./LICENSE-MIT) and the [Apache Software License v2](./LICENSE-APACHE) by way of the [Permissive License Stack](https://protocol.ai/blog/announcing-the-permissive-license-stack/). Use of this library implies your acceptance of these terms and conditions.

Things to keep in mind, while using this library:

- There are implicit invariants these contracts expect to hold.
- You should exhaustively read each contract you plan to use, top to bottom.
- **You can easily “shoot yourself in the foot” if you’re not careful with how you use the library.**

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

Better approach to import these libs is using the [NPM package](https://www.npmjs.com/package/filecoin-solidity-api) created for this .

```
$ npm install filecoin-solidity-api

```

#### Foundry (git)

> [!WARNING]
> When installing via git, it is a common error to use the `master` branch. This is a development branch that should be avoided in favor of tagged releases. The release process involves security measures that the `master` branch does not guarantee.

> [!WARNING]
> Foundry installs the latest version initially, but subsequent `forge update` commands will use the `master` branch.

```
$ forge install filecoin-project/filecoin-solidity
```

Add `filecoin-solidity-api=lib/filecoin-project/filecoin-solidity/` in `remappings.txt.`


#### Usage

In your smart contract, copy and paste these lines.

```solidity
import { MarketAPI } from "filecoin-solidity-api/contracts/v0.8/MarketAPI.sol";
import { CommonTypes } from "filecoin-solidity-api/contracts/v0.8/types/CommonTypes.sol";
import { MarketTypes } from "filecoin-solidity-api/contracts/v0.8/types/MarketTypes.sol";
import { BigIntCBOR } from "filecoin-solidity-api/contracts/v0.8/cbor/BigIntCbor.sol";
```

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

---

_**Information for `filecoin-solidity` lib developers is contained in [./lib-dev](./lib-dev)**_
