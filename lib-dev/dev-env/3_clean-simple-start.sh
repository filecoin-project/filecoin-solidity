#!/bin/sh

# set -e

INTERNALS_DIR="/var/lib/fil-sol/lib-dev/dev-env/.internal"
LOGPATH="$INTERNALS_DIR/dbg_log.txt"
LOCALNET_JSON="$INTERNALS_DIR/localnet.json"
DEVGEN_CAR="$INTERNALS_DIR/devgen.car"

ps -ef | grep 'lotus' | grep -v grep | awk '{print $2}' | xargs -r kill -9
rm -rf ~/.lotus-local-net/repo.lock  ~/.lotus-miner-local-net/repo.lock
sleep 5

rm -rf $INTERNALS_DIR
rm -rf ~/.genesis-sectors ~/.lotus-local-net ~/.lotus-miner-local-net

mkdir -p $INTERNALS_DIR
echo "start" >> $LOGPATH

cd $INTERNALS_DIR

verifregRootKey1=$(lotus-shed keyinfo new bls)
notary1=$(lotus-shed keyinfo new bls)

echo $verifregRootKey1 > $INTERNALS_DIR/verifier1.txt
echo $notary1 > $INTERNALS_DIR/notary1.txt

lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

lotus-seed genesis new $LOCALNET_JSON

lotus-seed genesis set-signers --threshold=1 --signers $verifregRootKey1 $LOCALNET_JSON

lotus-seed genesis add-miner $LOCALNET_JSON ~/.genesis-sectors/pre-seal-t01000.json

echo "LOTUS_FEVM_ENABLEETHRPC=true" >> $LOGPATH

export LOTUS_FEVM_ENABLEETHRPC=true

lotus daemon --lotus-make-genesis=$DEVGEN_CAR --genesis-template=$LOCALNET_JSON --bootstrap=false &

echo "Miner starting (20s delay) ..."
sleep 25

lotus wallet import --as-default ~/.genesis-sectors/pre-seal-t01000.key 

rm -rf $LOTUS_MINER_PATH

lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=~/.genesis-sectors --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync 

lotus-miner run --nosync &

sleep 25

lotus wallet import "$INTERNALS_DIR/bls-$verifregRootKey1.keyinfo"
lotus wallet import "$INTERNALS_DIR/bls-$notary1.keyinfo"

echo "DONE!" >> $LOGPATH