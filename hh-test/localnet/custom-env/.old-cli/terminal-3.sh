export LOTUS_PATH=~/.lotus-local-net 
export LOTUS_MINER_PATH=~/.lotus-miner-local-net
export LOTUS_SKIP_GENESIS_CHECK=_yes_ 
export CGO_CFLAGS_ALLOW="-D__BLST_PORTABLE__" 
export CGO_CFLAGS="-D__BLST_PORTABLE__" 

lotus wallet import bls-<root-key-1>.keyinfo 
.