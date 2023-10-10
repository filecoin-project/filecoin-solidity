use alloy_sol_types::{sol, SolType};

sol!{

    struct BigInt {
        bytes val;
        bool neg;
    }

    struct FilAddress {
        bytes data;
    }

    struct CreateMinerParams {
        FilAddress owner;
        FilAddress worker;
        RegisteredPoStProof window_post_proof_type;
        FilAddress peer;
        FilAddress[] multiaddrs;
    }

    struct CreateMinerReturn {
        FilAddress id_address;
        FilAddress robust_address;
    }

    struct MinerRawPowerReturn {
        BigInt raw_byte_power;
        bool meets_consensus_minimum;
    }

    enum RegisteredPoStProof {
        StackedDRGWinning2KiBV1,
        StackedDRGWinning8MiBV1,
        StackedDRGWinning512MiBV1,
        StackedDRGWinning32GiBV1,
        StackedDRGWinning64GiBV1,
        StackedDRGWindow2KiBV1,
        StackedDRGWindow8MiBV1,
        StackedDRGWindow512MiBV1,
        StackedDRGWindow32GiBV1,
        StackedDRGWindow64GiBV1,
        Invalid
    }

    function create_miner(CreateMinerParams memory params, uint256 value) public payable returns (CreateMinerReturn memory) {}

    function miner_count() public returns (uint64) {}

    function miner_consensus_count() public returns (int64) {}

    function network_raw_power() public returns (BigInt memory) {}

    function miner_raw_power(uint64 minerID) public returns (MinerRawPowerReturn memory) {}
}