#!/bin/sh

set -e

cd /go/lotus-local-net

./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false &

echo "Miner starting (20s delay) ..."
sleep 20

./lotus-miner run --nosync &

sleep 1000000000