#!/bin/sh

set -e

rm -rf bls-*.keyinfo localnet.json ~/.genesis-sectors $LOTUS_PATH/*.lock $LOTUS_MINER_PATH/*.lock

cd /go/lotus-local-net

verifregRootKey1=$(./lotus-shed keyinfo new bls)

echo $verifregRootKey1 > verifier1.txt

./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

./lotus-seed genesis new localnet.json

./lotus-seed genesis set-signers --threshold=1 --signers $verifregRootKey1 localnet.json

./lotus-seed genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json

./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false &

echo "Miner starting (20s delay) ..."
sleep 20

./lotus wallet import --as-default ~/.genesis-sectors/pre-seal-t01000.key 

./lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=~/.genesis-sectors --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync 

./lotus-miner run --nosync &

sleep 20

./lotus wallet import "bls-$verifregRootKey1.keyinfo"

notary1=$(./lotus wallet new secp256k1)

./lotus-shed verifreg add-verifier $verifregRootKey1 $notary1 1000

sleep 50

./lotus msig inspect f080

./lotus filplus list-notaries

# sleep 1000000000