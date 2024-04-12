#!/bin/sh

set -e

SLEEP_TIME=15

cd /go/lotus-local-net

./lotus daemon stop && ./lotus-miner stop

sleep $SLEEP_TIME

./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false &

echo "Miner starting ($SLEEP_TIME(s) delay) ..."
sleep $SLEEP_TIME

./lotus-miner run --nosync &

sleep $SLEEP_TIME