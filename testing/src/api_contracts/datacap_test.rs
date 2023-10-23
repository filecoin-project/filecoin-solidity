use alloy_sol_types::{sol, SolType};

sol!{

    struct BigInt {
        bytes val;
        bool neg;
    }

    struct FilAddress {
        bytes data;
    }

    struct GetAllowanceParams {
        FilAddress owner;
        FilAddress operator;
    }

    struct TransferParams {
        FilAddress to;
        BigInt amount;
        bytes operator_data;
    }

    struct TransferReturn {
        BigInt from_balance;
        BigInt to_balance;
        bytes recipient_data;
    }

    struct TransferFromParams {
        FilAddress from;
        FilAddress to;
        BigInt amount;
        bytes operator_data;
    }


    struct TransferFromReturn {
        BigInt from_balance;
        BigInt to_balance;
        BigInt allowance;
        bytes recipient_data;
    }

    struct IncreaseAllowanceParams {
        FilAddress operator;
        BigInt increase;
    }

    struct DecreaseAllowanceParams {
        FilAddress operator;
        BigInt decrease;
    }

    struct BurnFromParams {
        FilAddress owner;
        BigInt amount;
    }

    struct BurnFromReturn {
        BigInt balance;
        BigInt allowance;
    }


    function name() public returns (string memory) {}

    function symbol() public returns (string memory) {}

    function total_supply() public returns (BigInt memory) {}

    function balance(FilAddress memory addr) public returns (BigInt memory) {}

    function allowance(GetAllowanceParams memory params) public returns (BigInt memory) {}

    function transfer(TransferParams memory params) public returns (TransferReturn memory) {}

    function transfer_from(TransferFromParams memory params) public returns (TransferFromReturn memory) {}

    function increase_allowance(IncreaseAllowanceParams memory params) public returns (BigInt memory) {}

    function decrease_allowance(DecreaseAllowanceParams memory params) public returns (BigInt memory) {}

    function revoke_allowance(FilAddress memory operator) public returns (BigInt memory) {}

    function burn(BigInt memory amount) public returns (BigInt memory) {}

    function burn_from(BurnFromParams memory params) public returns (BurnFromReturn memory) {}

    function handle_filecoin_method(uint64 method, uint64 codec, bytes calldata params) public pure {}
}