use alloy_sol_types::{sol, SolType};

sol!{

    struct FilAddress {
        bytes data;
    }

    function resolve_address(FilAddress memory addr) public view returns (uint64) {}

    function resolve_eth_address(address addr) public view returns (uint64) {}

    function lookup_delegated_address(uint64 actor_id) public view returns (bytes memory) {}
}