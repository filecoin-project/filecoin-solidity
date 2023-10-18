use alloy_sol_types::{sol, SolType};

sol!{

    struct FilAddress {
        bytes data;
    }

    type FilActorId is uint64;

    function send(FilActorId target, uint256 amount) public {}

    function send(FilAddress memory target, uint256 amount) public {}
}