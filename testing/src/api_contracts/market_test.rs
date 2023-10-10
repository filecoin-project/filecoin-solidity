use alloy_sol_types::{sol, SolType};

sol!{

    struct FailCode {
        uint32 idx;
        uint32 code;
    }

    struct BatchReturn {
        uint32 success_count;
        FailCode[] fail_codes;
    }

    struct UniversalReceiverParams {
        uint32 type_;
        bytes payload;
    }

    struct BigInt {
        bytes val;
        bool neg;
    }

    struct FilAddress {
        bytes data;
    }

    struct Cid {
        bytes data;
    }

    struct DealLabel {
        bytes data;
        bool isString;
    }

    type FilActorId is uint64;

    type ChainEpoch is int64;

    struct GetDealTermReturn {
        ChainEpoch start;
        ChainEpoch end;
    }

    struct GetDealActivationReturn {
        ChainEpoch activated;
        ChainEpoch terminated;
    }
    
    struct DealProposal {
        Cid piece_cid;
        uint64 piece_size;
        bool verified_deal;
        FilAddress client;
        FilAddress provider;
        DealLabel label;
        int64 start_epoch;
        int64 end_epoch;
        BigInt storage_price_per_epoch;
        BigInt provider_collateral;
        BigInt client_collateral;
    }

    struct ClientDealProposal {
        DealProposal proposal;
        bytes client_signature;
    }

    struct PublishStorageDealsParams {
        
        ClientDealProposal[] deals;
    }

    struct PublishStorageDealsReturn {
        uint64[] ids;
        bytes valid_deals;
    }

    struct WithdrawBalanceParams {
        FilAddress provider_or_client;
        BigInt tokenAmount;
    }

    struct GetBalanceReturn {
        BigInt balance;
        BigInt locked;
    }

    struct GetDealDataCommitmentReturn {
        bytes data;
        uint64 size;
    }

    function add_balance(FilAddress memory providerOrClient, uint256 value) public payable {
    }

    function withdraw_balance(WithdrawBalanceParams memory params) public returns (BigInt memory) {
    }

    function get_balance(FilAddress memory addr) public returns (GetBalanceReturn memory) {
    }

    function get_deal_data_commitment(uint64 dealID) public returns (GetDealDataCommitmentReturn memory) {
    }

    function get_deal_client(uint64 dealID) public returns (uint64) {
    }

    function get_deal_provider(uint64 dealID) public returns (uint64) {
    }

    function get_deal_label(uint64 dealID) public returns (DealLabel memory) {
    }

    function get_deal_total_price(uint64 dealID) public returns (BigInt memory) {
    }

    function get_deal_client_collateral(uint64 dealID) public returns (BigInt memory) {
    }

    function get_deal_provider_collateral(uint64 dealID) public returns (BigInt memory) {
    }

    function get_deal_term(uint64 dealID) public returns (GetDealTermReturn memory) {
    }

    function get_deal_verified(uint64 dealID) public returns (bool) {
    }

    function get_deal_activation(uint64 dealID) public returns (GetDealActivationReturn memory) {
    }

    function publish_storage_deals(PublishStorageDealsParams memory params) public returns (PublishStorageDealsReturn memory) {}

}