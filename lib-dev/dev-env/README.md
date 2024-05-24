# Developer Environment

## Overview

To make the developer environment uniform across contributors (different OS, etc.), it is best to do `filecoin-solidity` library development inside this containarized environment.

Docker image supports Rust and all other dependencies (see [Dockerfile](./Dockerfile)) - any update in versions will require updating and rebuilding the image.

**Notes:**

-   The docker container has access to the complete project directory (mounted at `/var/lib/fil-sol`) and all changes are reflected.

-   Also, VS Code can be attached to the container using its [Docker Plugin](https://code.visualstudio.com/docs/containers/overview).

### Initial setup

From project's root

```
cp .env.example .env
```

Update `.env`

Source ENV vars:

```
source .env
```

### Building the Docker image

```
docker buildx build --platform=linux/amd64 -t ${FIL_SOL_DOCKER_IMG} .
```

### Starting Dev. Environment

Set up the container

```
docker compose up
```

Enter into the container from VS Code (recommended), or run:

```
docker exec -it lotus /bin/bash
```

Install Solc

```
make install_solc_linux
```

For more control, run (for `localnet`):

```
./lib-dev/dev-env/1_clean-start-localnet.sh
```

For both **network** = `calibnet` || `localnet`, run:

```
export HH_NETWORK=<network> && npx hardhat test
```

or use (basic):

For `localnet`

```
make start_localnet
make test_hh_localnet
```

For `calibnet`

```
make test_hh_calibnet
```

### Running Rust tests (make sure you are not sometimes compiling from host, and sometimes from container):

```
make test_integration
```

## Useful notes:

-   It's advised (due to machine resources) to run either localnet or rust tests.
-   [Lotus CLI Docs](https://lotus.filecoin.io/lotus/manage/lotus-cli/)
    -   especially `evm invoke` section
-   [Lotus Miner CLI Docs](https://lotus.filecoin.io/storage-providers/operate/lotus-miner-cli/)
