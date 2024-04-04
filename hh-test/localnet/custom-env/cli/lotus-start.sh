export LOTUS_PATH=~/.lotus-local-net
export LOTUS_MINER_PATH=~/.lotus-miner-local-net
export LOTUS_SKIP_GENESIS_CHECK=_yes_
export CGO_CFLAGS_ALLOW="-D__BLST_PORTABLE__"
export CGO_CFLAGS="-D__BLST_PORTABLE__"

# export LOTUS_FEVM_ENABLEETHRPC=true
# # export LOTUS_API_LISTENADDRESS=/dns/lotus/tcp/1234/http
# export LOTUS_LIBP2P_LISTENADDRESSES=/ip4/0.0.0.0/tcp/9090
# # export GENESIS_PATH=/var/lib/genesis
# # export SECTOR_SIZE=2048
# # export MNEMONIC="test test test test test test test test test test test junk"

cd lotus-local-net

./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false 

cd lotus-local-net && ./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false 


# lotus-shed verifreg add-verifier t3qodgeu66w4ahxgf5nquyofpldqtq5skaevgeisebql4evrewv5vxko5w2a5zgsomy7bj63xaaa6gjntrl4la t1oqollf6l55zwxfhv5jtwwev4o4ivuyy6ncwj7ua 100

# lotus msig approve  --from=t3qe7a5azkg6okbrhcgpf4tfhfwc6yn2pbtjavvg5e3oxmnjuw3gxrr55odtqddckcfswj6l7efokkmsjfq56q f080 0 t0101 f06 0 2 825501741cb597cbef736b94f5ea676b12bc77115a631e4400989680
