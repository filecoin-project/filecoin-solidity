#!/bin/sh

# set -e

INTERNALS_DIR="/var/lib/fil-sol/lib-dev/dev-env/.internal"
LOGPATH="$INTERNALS_DIR/dbg_log.txt"
LOCALNET_JSON="$INTERNALS_DIR/localnet.json"
DEVGEN_CAR="$INTERNALS_DIR/devgen.car"

ps -ef | grep 'lotus' | grep -v grep | awk '{print $2}' | xargs -r kill -9
rm -rf ~/.lotus-local-net/repo.lock  ~/.lotus-miner-local-net/repo.lock
