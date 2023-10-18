use alloy_sol_types::{sol, SolType};

sol!{

    type FilActorId is uint64;

    struct AuthenticateMessageParams {
        bytes signature;
        bytes message;
    }

    struct UniversalReceiverParams {
        uint32 type_;
        bytes payload;
    }

    function authenticate_message(FilActorId target, AuthenticateMessageParams memory params) public {}

    function universal_receiver_hook(FilActorId target, UniversalReceiverParams memory params) public {}
}