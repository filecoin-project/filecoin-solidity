#!/bin/sh

LOCK_FILE=localnet-setup-running.lock

if [ -f $LOCK_FILE ]; then
    echo "ERR: Cannot run tests - Localnet setup is still running."
else
    echo "Localnet setup done - Running tests ..."
    export HH_NETWORK=localnet && npx hardhat test
fi