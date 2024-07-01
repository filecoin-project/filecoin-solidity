#!/bin/sh

INTERNALS_DIR="/var/lib/fil-sol/lib-dev/dev-env/.internal"
LOGPATH="$INTERNALS_DIR/dbg_log.txt"
LOCALNET_JSON="$INTERNALS_DIR/localnet.json"
DEVGEN_CAR="$INTERNALS_DIR/devgen.car"

# set -e

SLEEP_TIME=20

ps -ef | grep 'lotus' | grep -v grep | awk '{print $2}' | xargs -r kill -9
rm -rf ~/.lotus-local-net/repo.lock  ~/.lotus-miner-local-net/repo.lock
sleep 5

# lotus-miner stop
# lotus daemon stop 
# sleep $SLEEP_TIME

echo "Lotus starting ..." >> $LOGPATH
lotus daemon start &

echo "Miner starting ($SLEEP_TIME(s) delay) ..." >> $LOGPATH
sleep $SLEEP_TIME
lotus-miner run --nosync &
sleep $SLEEP_TIME

echo "Restart script done" >> $LOGPATH