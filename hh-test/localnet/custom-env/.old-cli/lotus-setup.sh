export LOTUS_PATH=~/.lotus-local-net
export LOTUS_MINER_PATH=~/.lotus-miner-local-net
export LOTUS_SKIP_GENESIS_CHECK=_yes_
export CGO_CFLAGS_ALLOW="-D__BLST_PORTABLE__"
export CGO_CFLAGS="-D__BLST_PORTABLE__"

cd lotus-local-net

root_key_1=$(./lotus-shed keyinfo new bls)
# t3qodgeu66w4ahxgf5nquyofpldqtq5skaevgeisebql4evrewv5vxko5w2a5zgsomy7bj63xaaa6gjntrl4la

root_key_2=$(./lotus-shed keyinfo new bls)
# t3qe7a5azkg6okbrhcgpf4tfhfwc6yn2pbtjavvg5e3oxmnjuw3gxrr55odtqddckcfswj6l7efokkmsjfq56q

./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

./lotus-seed genesis new localnet.json

./lotus-seed genesis set-signers --threshold=2 --signers $root_key_1 --signers $root_key_2 localnet.json

./lotus-seed genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json

./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false 

#notary
# t1oqollf6l55zwxfhv5jtwwev4o4ivuyy6ncwj7ua

./lotus-shed verifreg add-verifier t3qodgeu66w4ahxgf5nquyofpldqtq5skaevgeisebql4evrewv5vxko5w2a5zgsomy7bj63xaaa6gjntrl4la t1oqollf6l55zwxfhv5jtwwev4o4ivuyy6ncwj7ua 100

lotus msig approve  --from=t3qe7a5azkg6okbrhcgpf4tfhfwc6yn2pbtjavvg5e3oxmnjuw3gxrr55odtqddckcfswj6l7efokkmsjfq56q f080 0 t0101 f06 0 2 825501741cb597cbef736b94f5ea676b12bc77115a631e4400989680
