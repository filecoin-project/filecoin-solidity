use alloy_sol_types::{sol, SolType};

sol!{

    struct BigInt {
        bytes val;
        bool neg;
    }

    struct FilAddress {
        bytes data;
    }

    type FilActorId is uint64;

    struct FailCode {
        uint32 idx;
        uint32 code;
    }

    struct BatchReturn {
        uint32 success_count;
        FailCode[] fail_codes;
    }

    struct GetClaimsParams {
        FilActorId provider;
        FilActorId[] claim_ids;
    }

    struct GetClaimsReturn {
        BatchReturn batch_info;
        Claim[] claims;
    }

    struct AddVerifiedClientParams {
        FilAddress addr;
        BigInt allowance;
    }

    struct RemoveExpiredAllocationsParams {
        FilActorId client;
        FilActorId[] allocation_ids;
    }

    struct RemoveExpiredAllocationsReturn {
        FilActorId[] considered;
        BatchReturn results;
        BigInt datacap_recovered;
    }

    struct RemoveExpiredClaimsParams {
        FilActorId provider;
        FilActorId[] claim_ids;
    }

    struct RemoveExpiredClaimsReturn {
        FilActorId[] considered;
        BatchReturn results;
    }

    struct ExtendClaimTermsParams {
        ClaimTerm[] terms;
    }

    struct ClaimTerm {
        FilActorId provider;
        FilActorId claim_id;
        int64 term_max;
    }

    struct Claim {
        FilActorId provider;
        FilActorId client;
        bytes data;
        uint64 size;
        int64 term_min;
        int64 term_max;
        int64 term_start;
        FilActorId sector;
    }

    function get_claims(GetClaimsParams memory params) public returns (GetClaimsReturn memory) {}

    function add_verified_client(AddVerifiedClientParams memory params) public {}

    function remove_expired_allocations(
        RemoveExpiredAllocationsParams memory params
    ) public returns (RemoveExpiredAllocationsReturn memory) {}

    function extend_claim_terms(ExtendClaimTermsParams memory params) public returns (BatchReturn memory) {}

    function remove_expired_claims(RemoveExpiredClaimsParams memory params) public returns (RemoveExpiredClaimsReturn memory) {}
}