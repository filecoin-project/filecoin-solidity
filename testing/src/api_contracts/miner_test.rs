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

    type ChainEpoch is int64;

    struct GetOwnerReturn {
        FilAddress owner;
        FilAddress proposed;
    } 

    struct GetVestingFundsReturn {
        VestingFunds[] vesting_funds;
    }

    struct ChangeBeneficiaryParams {
        FilAddress new_beneficiary;
        BigInt new_quota;
        ChainEpoch new_expiration;
    }


    struct ChangeWorkerAddressParams {
        FilAddress new_worker;
        FilAddress[] new_control_addresses;
    }

    struct ChangeMultiaddrsParams {
        FilAddress[] new_multi_addrs;
    }

    struct GetMultiaddrsReturn {
        FilAddress[] multi_addrs;
    }

    struct VestingFunds {
        ChainEpoch epoch;
        BigInt amount;
    }

    struct BeneficiaryTerm {
        BigInt quota;
        BigInt used_quota;
        ChainEpoch expiration;
    }

    struct ActiveBeneficiary {
        FilAddress beneficiary;
        BeneficiaryTerm term;
    }

    struct PendingBeneficiaryChange {
        FilAddress new_beneficiary;
        BigInt new_quota;
        ChainEpoch new_expiration;
        bool approved_by_beneficiary;
        bool approved_by_nominee;
    }

    function GetBeneficiaryReturn ((ActiveBeneficiary, PendingBeneficiaryChange) memory values) public view{}

    function get_owner(FilActorId target) public returns (GetOwnerReturn memory) {}

    function change_owner_address(FilActorId target, FilAddress memory addr) public {}

    function is_controlling_address(FilActorId target, FilAddress memory addr) public returns (bool) {}

    function get_sector_size(FilActorId target) public returns (uint64) {}

    function get_available_balance(FilActorId target) public returns (BigInt memory) {}

    function get_vesting_funds(FilActorId target) public returns (GetVestingFundsReturn memory) {}

    function change_beneficiary(FilActorId target, ChangeBeneficiaryParams memory params) public {}

    function get_beneficiary(FilActorId target) public returns ((ActiveBeneficiary, PendingBeneficiaryChange) memory) {}

    function change_worker_address(FilActorId target, ChangeWorkerAddressParams memory params) public {}

    function change_peer_id(FilActorId target, FilAddress memory newId) public {}

    function change_multiaddresses(FilActorId target, ChangeMultiaddrsParams memory params) public {}

    function repay_debt(FilActorId target) public {}

    function confirm_change_worker_address(FilActorId target) public {}

    function get_peer_id(FilActorId target) public returns (FilAddress memory) {}

    function get_multiaddresses(FilActorId target) public returns (GetMultiaddrsReturn memory) {}

    function withdraw_balance(FilActorId target, BigInt memory amount) public returns (BigInt memory) {}

    //helpers
    function encode_vesting_funds(VestingFunds[] vesting_funds) public {}
}