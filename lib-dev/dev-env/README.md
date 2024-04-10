# Developer Environment

## Overview

To make the developer environment uniform across contributors (different OS, etc.), it is best to do `filecoin-solidity` library development inside this containarized environment.

**Notes:**

-   The docker container has access to the complete project directory (mounted at `/var/lib/fil-sol`) and all changes are reflected.

-   Also, VS Code can be attached to the container using its [Docker Plugin](https://code.visualstudio.com/docs/containers/overview).

### Initial setup

```
cp .env.example .env && source .env
```

### Building the Docker image

```
docker buildx build --platform=linux/amd64 -t ${FIL_SOL_DOCKER_IMG} .
```

### Starting Dev. Environment

```
docker compose up
```
