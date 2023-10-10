use fil_actor_eam::Return;
use fil_actor_evm::Method as EvmMethods;
use fil_actors_runtime::{
    runtime::builtins, DATACAP_TOKEN_ACTOR_ADDR, EAM_ACTOR_ADDR, SYSTEM_ACTOR_ADDR,
    VERIFIED_REGISTRY_ACTOR_ADDR,
};
use fvm::executor::{ApplyKind, Executor};
use fvm_integration_tests::dummy::DummyExterns;
use fvm_integration_tests::tester::Account;
use fvm_ipld_encoding::strict_bytes;
use fvm_ipld_encoding::RawBytes;
use fvm_shared::address::Address;
use fvm_shared::econ::TokenAmount;
use fvm_shared::message::Message;
use serde::{Deserialize as SerdeDeserialize, Serialize as SerdeSerialize};
use alloy_sol_types::{SolCall, sol_data, SolType};
use alloy_primitives::{fixed_bytes};

use testing::{setup, helpers, api_contracts};
use testing::GasResult;
use testing::parse_gas;

const WASM_COMPILED_PATH: &str = "../build/v0.8/tests/DataCapApiTest.bin";

#[derive(SerdeSerialize, SerdeDeserialize)]
#[serde(transparent)]
pub struct CreateExternalParams(#[serde(with = "strict_bytes")] pub Vec<u8>);

#[test]
fn datacap_tests() {
    println!("Testing solidity API");

    let mut gas_result: GasResult = vec![];
    let (mut tester, manifest) = setup::setup_tester();

    // As the governor address for datacap is 200, we create many many address in order to initialize the ID 200 with some tokens
    // and make it a valid address to use.
    let sender: [Account; 300] = tester.create_accounts().unwrap();

    // Set datacap actor
    let state_tree = tester.state_tree.as_mut().unwrap();
    helpers::set_datacap_actor(
        state_tree,
        *manifest.code_by_id(builtins::Type::DataCap as u32).unwrap(),
    )
    .unwrap();
    helpers::set_verifiedregistry_actor(
        state_tree,
        *manifest
            .code_by_id(builtins::Type::VerifiedRegistry as u32)
            .unwrap(),
    )
    .unwrap();

    // Create embryo address to deploy the contract on it (assign some FILs to it)
    let tmp = hex::decode("DAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5").unwrap();
    let embryo_eth_address = tmp.as_slice();
    let embryo_delegated_address = Address::new_delegated(10, embryo_eth_address).unwrap();
    tester
        .create_placeholder(&embryo_delegated_address, TokenAmount::from_whole(100))
        .unwrap();

    println!(
        "Embryo address delegated type [{}]",
        embryo_delegated_address
    );
    println!(
        "Embryo address delegated type on hex [{}]",
        hex::encode(embryo_delegated_address.to_bytes())
    );
    // println!("Embryo address ID type on decimal [{}]",embryo_actor_id);
    // println!("Embryo address ID type on hex [{}]",hex::encode(Address::new_id(embryo_actor_id).to_bytes()));

    println!(
        "{}",
        format!(
            "Sender address id [{}] and bytes [{}]",
            &sender[0].0,
            hex::encode(&sender[0].1.to_bytes())
        )
    );
    println!(
        "{}",
        format!(
            "Sender address id [{}] and bytes [{}]",
            &sender[1].0,
            hex::encode(&sender[1].1.to_bytes())
        )
    );
    println!(
        "{}",
        format!(
            "Sender address id [{}] and bytes [{}]",
            &sender[2].0,
            hex::encode(&sender[2].1.to_bytes())
        )
    );
    println!(
        "{}",
        format!(
            "Sender address id [{}] and bytes [{}]",
            &sender[3].0,
            hex::encode(&sender[3].1.to_bytes())
        )
    );

    // Instantiate machine
    tester.instantiate_machine(DummyExterns).unwrap();

    let executor = tester.executor.as_mut().unwrap();

    // Try to call "constructor"
    println!("Try to call constructor on verifreg actor");

    let root_key = Address::new_id(199);

    let message = Message {
        from: SYSTEM_ACTOR_ADDR,
        to: VERIFIED_REGISTRY_ACTOR_ADDR,
        gas_limit: 1000000000,
        method_num: 1,
        params: RawBytes::serialize(root_key).unwrap(),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Implicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    // Try to call "constructor"
    println!("Try to call constructor on datacap actor");

    let message = Message {
        from: SYSTEM_ACTOR_ADDR,
        to: DATACAP_TOKEN_ACTOR_ADDR,
        gas_limit: 1000000000,
        method_num: 1,
        params: RawBytes::serialize(Address::new_id(200)).unwrap(),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Implicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    // First we deploy the contract in order to actually have an actor running on the embryo address
    println!("Calling init actor (EVM)");

    let evm_bin = setup::load_evm(WASM_COMPILED_PATH);

    let constructor_params = CreateExternalParams(evm_bin);

    let message = Message {
        from: embryo_delegated_address,
        to: EAM_ACTOR_ADDR,
        gas_limit: 1000000000,
        method_num: 4,
        sequence: 0,
        params: RawBytes::serialize(constructor_params).unwrap(),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let exec_return: Return = RawBytes::deserialize(&res.msg_receipt.return_data).unwrap();

    println!(
        "Contract address ID type on decimal [{}]",
        exec_return.actor_id
    );
    println!(
        "Contract address ID type on hex [{}]",
        hex::encode(Address::new_id(exec_return.actor_id).to_bytes())
    );
    match exec_return.robust_address {
        Some(addr) => println!("Contract address robust type [{}]", addr),
        None => (),
    }

    println!(
        "Contract address eth address type [{}]",
        hex::encode(exec_return.eth_address.0)
    );

    let contract_actor_id = exec_return.actor_id;

    // We need to mint tokens for the contract actor address in order to be able to execute methods like transfer, etc
    // NOTICE: The only address that can mint tokens is the governor, which is defined on the ref-fvm repo (on integration module)
    // NOTICE: We firt deploy the contract because the embryo address by its own cannot receive minted tokens.
    println!("Minting some tokens on datacap actor");

    let mint_params_1 = fil_actor_datacap::MintParams {
        to: Address::new_id(contract_actor_id),
        amount: TokenAmount::from_whole(1000),
        operators: vec![Address::new_id(sender[0].0), Address::new_id(sender[1].0)],
    };

    let message = Message {
        from: Address::new_id(200),
        to: DATACAP_TOKEN_ACTOR_ADDR,
        gas_limit: 1000000000,
        method_num: 116935346, // Coming from get_method_nums command
        sequence: 0,
        params: RawBytes::serialize(mint_params_1).unwrap(),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    println!("Minting more tokens on datacap actor");

    let mint_params_2 = fil_actor_datacap::MintParams {
        to: Address::new_id(sender[0].0),
        amount: TokenAmount::from_whole(1000),
        operators: vec![Address::new_id(contract_actor_id)],
    };

    let message = Message {
        from: Address::new_id(200),
        to: DATACAP_TOKEN_ACTOR_ADDR,
        gas_limit: 1000000000,
        method_num: 116935346, // Coming from get_method_nums command
        sequence: 1,
        params: RawBytes::serialize(mint_params_2).unwrap(),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    println!("Calling `name`");

    let abi_encoded_call = api_contracts::datacap_test::nameCall{}.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(contract_actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 0,
        params: RawBytes::new(hex::decode(
            // "4406FDDE03"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("name".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_name = String::from("DataCap");

    let abi_encoded_call = sol_data::String::abi_encode(&expected_name);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "5860000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000074461746143617000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `symbol`");

    let abi_encoded_call = api_contracts::datacap_test::symbolCall{}.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(contract_actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 1,
        params: RawBytes::new(hex::decode(
            // "4495D89B41"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("symbol".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_symbol = String::from("DCAP");

    let abi_encoded_call = sol_data::String::abi_encode(&expected_symbol);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "5860000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000044443415000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `total_supply`");

    let abi_encoded_call = api_contracts::datacap_test::total_supplyCall{}.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(contract_actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 2,
        params: RawBytes::new(hex::decode(
            // "443940E9EE"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("total_supply".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_total_supply = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("6c6b935b8bbd400000").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::BigInt::abi_encode(&expected_total_supply);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000096c6b935b8bbd4000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `balance`");

    let abi_encoded_call = api_contracts::datacap_test::balanceCall{
        addr: api_contracts::datacap_test::FilAddress{
            data: vec![0_u8, 66]
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 3,
            params: RawBytes::new(hex::decode(
                // "5884446CE9890000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020066000000000000000000000000000000000000000000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("balance".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_balance = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::BigInt::abi_encode(&expected_balance);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `allowance`");

    let abi_encoded_call = api_contracts::datacap_test::allowanceCall{
        params: api_contracts::datacap_test::GetAllowanceParams{
            owner: api_contracts::datacap_test::FilAddress{
                data: sender[0].1.to_bytes()
            },
            operator: api_contracts::datacap_test::FilAddress{
                data: sender[1].1.to_bytes()
            }
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 4,
            params: RawBytes::new(hex::decode(
                // "5901243C41053A0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000A000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000015011EDA43D05CA6D7D637E7065EF6B8C5DB89E5FB0C00000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001501DCE5B7F69E73494891556A350F8CC357614916D50000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("allowance".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_allowance = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::BigInt::abi_encode(&expected_allowance);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `transfer`");

    let abi_encoded_call = api_contracts::datacap_test::transferCall{
        params: api_contracts::datacap_test::TransferParams{
            to: api_contracts::datacap_test::FilAddress{
                data: vec![0x00_u8, 0xc8, 0x01]
            },
            amount: api_contracts::datacap_test::BigInt{
                val: fixed_bytes!("1BC16D674EC80000").to_vec(),
                neg: false
            },
            operator_data: fixed_bytes!("").to_vec()
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 5,
            params: RawBytes::new(hex::decode(
                // "5901849013A5110000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000C000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000300C80100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000081BC16D674EC800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("transfer".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_transfer_return = api_contracts::datacap_test::TransferReturn{
        from_balance: api_contracts::datacap_test::BigInt{
            val: fixed_bytes!("361A08405E8FD80000").to_vec(),
            neg: false
        },
        to_balance: api_contracts::datacap_test::BigInt{
            val: fixed_bytes!("1BC16D674EC80000").to_vec(),
            neg: false
        },
        recipient_data: fixed_bytes!("").to_vec()
    };

    let abi_encoded_call = api_contracts::datacap_test::TransferReturn::abi_encode(&expected_transfer_return);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "5901a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009361a08405e8fd8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000081bc16d674ec800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `transfer_from`");

    let abi_encoded_call = api_contracts::datacap_test::transfer_fromCall{
        params: api_contracts::datacap_test::TransferFromParams{
            from: api_contracts::datacap_test::FilAddress{
                data: sender[0].1.to_bytes()
            },
            to: api_contracts::datacap_test::FilAddress{
                data: vec![0x00_u8, 0xc8, 0x01]
            },
            amount: api_contracts::datacap_test::BigInt{
                val: fixed_bytes!("3782DACE9D900000").to_vec(),
                neg: false
            },
            operator_data: fixed_bytes!("").to_vec()
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(cbor_encoded.as_str());

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 6,
            params: RawBytes::new(hex::decode(
                // "59020475F293130000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000E0000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001C000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000015011EDA43D05CA6D7D637E7065EF6B8C5DB89E5FB0C00000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000300C80100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083782DACE9D9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("transfer_from".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_transfer_from = api_contracts::datacap_test::TransferFromReturn{
        from_balance: api_contracts::datacap_test::BigInt{
            val: fixed_bytes!("35FE46D2F741100000").to_vec(),
            neg: false
        },
        to_balance: api_contracts::datacap_test::BigInt{
            val: fixed_bytes!("53444835EC580000").to_vec(),
            neg: false
        },
        allowance: api_contracts::datacap_test::BigInt{
            val: fixed_bytes!("02F050FE938943ACC427E27BB162700000").to_vec(),
            neg: false
        },
        recipient_data: fixed_bytes!("").to_vec()
    };

    let abi_encoded_call = api_contracts::datacap_test::TransferFromReturn::abi_encode(&expected_transfer_from);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "5902400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000935fe46d2f741100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000853444835ec58000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001102f050fe938943acc427e27bb1627000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `burn`");

    let amount = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("0DE0B6B3A7640000").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::burnCall{
        amount: amount
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(cbor_encoded.as_str());

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 7,
            params: RawBytes::new(hex::decode(
                // "58a477898bd50000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006de0b6b3a76400000000000000000000000000000000000000000000000000000"
                // "58A477898BD500000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080DE0B6B3A7640000000000000000000000000000000000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("burn".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_amount = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("360C2789AAE8740000").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::BigInt::abi_encode(&expected_amount.clone());
    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009360c2789aae87400000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `burn_from`");

    let amount = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("0DE0B6B3A7640000").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::burn_fromCall{
        params: api_contracts::datacap_test::BurnFromParams{
            owner: api_contracts::datacap_test::FilAddress{
                data: sender[0].1.to_bytes()
            },
            amount: amount
        }
    }.abi_encode();

    let cbor_encoded =  api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 8,
            params: RawBytes::new(hex::decode(
                // "590144D88FE6230000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000A000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000015011EDA43D05CA6D7D637E7065EF6B8C5DB89E5FB0C00000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080DE0B6B3A7640000000000000000000000000000000000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("burn_from".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_burn_from = api_contracts::datacap_test::BurnFromReturn{
        balance: api_contracts::datacap_test::BigInt{
            val: fixed_bytes!("35F0661C4399AC0000").to_vec(),
            neg: false
        },
        allowance: api_contracts::datacap_test::BigInt{
            val: fixed_bytes!("02F050FE938943ACC41A01C4FDBB0C0000").to_vec(),
            neg: false
        },
    };

    let abi_encoded_call = api_contracts::datacap_test::BurnFromReturn::abi_encode(&expected_burn_from);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "5901600000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000935f0661c4399ac0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001102f050fe938943acc41a01c4fdbb0c0000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `allowance`");

    let abi_encoded_call = api_contracts::datacap_test::allowanceCall{
        params: api_contracts::datacap_test::GetAllowanceParams{
            owner: api_contracts::datacap_test::FilAddress{
                data: sender[0].1.to_bytes()
            },
            operator: api_contracts::datacap_test::FilAddress{
                data: vec![0_u8, 0x91, 0x03]
            }
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 9,
            params: RawBytes::new(hex::decode(
                // "5901243C41053A0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000A000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000015011EDA43D05CA6D7D637E7065EF6B8C5DB89E5FB0C0000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030091030000000000000000000000000000000000000000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("allowance".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_allowance = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("02F050FE938943ACC41A01C4FDBB0C0000").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::BigInt::abi_encode(&expected_allowance);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001102f050fe938943acc41a01c4fdbb0c0000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `increase_allowance`");

    let abi_encoded_call = api_contracts::datacap_test::increase_allowanceCall{
        params: api_contracts::datacap_test::IncreaseAllowanceParams{
            operator: api_contracts::datacap_test::FilAddress{
                data: sender[0].1.to_bytes()
            },
            increase: api_contracts::datacap_test::BigInt{
                val: fixed_bytes!("3635C9ADC5DEA00000").to_vec(),
                neg: false
            }
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(cbor_encoded.as_str());

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 10,
            params: RawBytes::new(hex::decode(
                // "590144862aad880000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000015011eda43d05ca6d7d637e7065ef6b8c5db89e5fb0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000093635c9adc5dea000000000000000000000000000000000000000000000000000"
                // "590144862AAD880000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000A000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000015011EDA43D05CA6D7D637E7065EF6B8C5DB89E5FB0C00000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000093635C9ADC5DEA000000000000000000000000000000000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("increase_allowance".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_allowance = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("02f050fe938943acfa952f0445dea00000").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::BigInt::abi_encode(&expected_allowance);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001102f050fe938943acfa952f0445dea00000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `decrease_allowance`");

    let amount = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("3635C9ADC5DEA00000").to_vec(),
        neg: false
    }; 

    let abi_encoded_call = api_contracts::datacap_test::decrease_allowanceCall{
        params: api_contracts::datacap_test::DecreaseAllowanceParams{
            operator: api_contracts::datacap_test::FilAddress{
                data: sender[0].1.to_bytes()
            },
            decrease: amount
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(cbor_encoded.as_str());

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 11,
            params: RawBytes::new(hex::decode(
                // "59014438F43B6E0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000A000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000015011EDA43D05CA6D7D637E7065EF6B8C5DB89E5FB0C00000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000093635C9ADC5DEA000000000000000000000000000000000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("decrease_allowance".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_allowance = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("02f050fe938943acc45f65568000000000").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::BigInt::abi_encode(&expected_allowance);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001102f050fe938943acc45f65568000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `revoke_allowance`");

    let amount = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("3635C9ADC5DEA00000").to_vec(),
        neg: false
    }; 

    let abi_encoded_call = api_contracts::datacap_test::revoke_allowanceCall{
        operator: api_contracts::datacap_test::FilAddress{
            data: sender[0].1.to_bytes()
        },
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(cbor_encoded.as_str());

    let message = Message {
            from: sender[0].1,
            to: Address::new_id(contract_actor_id),
            gas_limit: 1000000000,
            method_num: EvmMethods::InvokeContract as u64,
            sequence: 12,
            params: RawBytes::new(hex::decode(
                // "588455E1C7A3000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000015011EDA43D05CA6D7D637E7065EF6B8C5DB89E5FB0C0000000000000000000000"
                cbor_encoded.as_str()
            ).unwrap()),
            ..Message::default()
        };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("revoke_allowance".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_allowance = api_contracts::datacap_test::BigInt{
        val: fixed_bytes!("02f050fe938943acc45f65568000000000").to_vec(),
        neg: false
    };

    let abi_encoded_call = api_contracts::datacap_test::BigInt::abi_encode(&expected_allowance);

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001102f050fe938943acc45f65568000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    let table = testing::create_gas_table(gas_result);
    testing::save_gas_table(&table, "datacap");

    table.printstd();
}
