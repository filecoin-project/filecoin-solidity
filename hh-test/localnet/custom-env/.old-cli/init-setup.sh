export LOTUS_PATH=~/.lotus-local-net
export LOTUS_MINER_PATH=~/.lotus-miner-local-net
export LOTUS_SKIP_GENESIS_CHECK=_yes_
export CGO_CFLAGS_ALLOW="-D__BLST_PORTABLE__"
export CGO_CFLAGS="-D__BLST_PORTABLE__"

# git clone https://github.com/filecoin-project/lotus lotus-local-net

cd lotus-local-net

git checkout releases

rm -rf ~/.genesis-sectors

make 2k

./lotus fetch-params 2048

make lotus-shed