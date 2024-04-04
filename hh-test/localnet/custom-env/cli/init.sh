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

rm -rf lotus-local-net

git clone https://github.com/filecoin-project/lotus lotus-local-net

cd lotus-local-net

git checkout releases

rm -rf ~/.genesis-sectors

make 2k

./lotus fetch-params 2048

make lotus-shed

