export LOTUS_PATH=~/.lotus-local-net
export LOTUS_MINER_PATH=~/.lotus-miner-local-net
export LOTUS_SKIP_GENESIS_CHECK=_yes_
export CGO_CFLAGS_ALLOW="-D__BLST_PORTABLE__"
export CGO_CFLAGS="-D__BLST_PORTABLE__"

# export LOTUS_FEVM_ENABLEETHRPC=true
# export LOTUS_API_LISTENADDRESS=/dns/lotus/tcp/1234/http
# export LOTUS_LIBP2P_LISTENADDRESSES=/ip4/0.0.0.0/tcp/9090
# export GENESIS_PATH=/var/lib/genesis
# export SECTOR_SIZE=2048
# export MNEMONIC="test test test test test test test test test test test junk"

cd lotus-local-net

rm -rf localnet.json

echo "Creating VerifReg Root Keys:"
verifreg_root_key_1=$(lotus-shed keyinfo new bls)

verifreg_root_key_2=$(lotus-shed keyinfo new bls)
echo "-> Created keys:"
echo "---- K1: $verifreg_root_key_1"
echo "---- K2: $verifreg_root_key_2"

echo "\n"

echo "Genesis setup ..."
./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

./lotus-seed genesis new localnet.json

./lotus-seed genesis set-signers --threshold=2 --signers $root_key_1 --signers $root_key_2 localnet.json

./lotus-seed genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json

echo "\n"