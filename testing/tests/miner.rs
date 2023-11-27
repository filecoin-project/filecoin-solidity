use bls_signatures::Serialize;
use fil_actor_eam::Return;
use fil_actor_evm::Method as EvmMethods;
use fil_actor_init::ExecReturn;
use fil_actors_runtime::{runtime::builtins, EAM_ACTOR_ADDR, SYSTEM_ACTOR_ADDR, REWARD_ACTOR_ADDR, STORAGE_MARKET_ACTOR_ADDR, STORAGE_POWER_ACTOR_ADDR};
use fvm::executor::{ApplyKind, Executor};
use fvm::state_tree::ActorState;
use fvm_integration_tests::dummy::DummyExterns;
use fvm_integration_tests::tester::Account;
use fvm_ipld_encoding::CborStore;
use fvm_ipld_encoding::RawBytes;
use fvm_ipld_encoding::{strict_bytes, tuple::*, BytesDe};
use fvm_shared::address::Address;
use fvm_shared::econ::TokenAmount;
use fvm_shared::message::Message;
use fvm_shared::sector::RegisteredPoStProof;
use multihash::Code;
use rand_core::OsRng;
use serde::{Deserialize as SerdeDeserialize, Serialize as SerdeSerialize};
use alloy_primitives::{fixed_bytes};
use alloy_sol_types::{SolCall, SolType, sol_data};


use testing::{setup, helpers, api_contracts};

use testing::GasResult;
use testing::parse_gas;

const WASM_COMPILED_PATH: &str = "../build/v0.8/tests/MinerApiTest.bin";

#[derive(Serialize_tuple, Deserialize_tuple, Debug, Clone, Eq, PartialEq)]
pub struct CreateMinerParams {
    pub owner: Address,
    pub worker: Address,
    pub window_post_proof_type: RegisteredPoStProof,
    #[serde(with = "strict_bytes")]
    pub peer: Vec<u8>,
    pub multiaddrs: Vec<BytesDe>,
}

#[derive(Serialize_tuple, Deserialize_tuple, Clone, Debug)]
struct State {
    empty: bool,
}

#[derive(SerdeSerialize, SerdeDeserialize)]
#[serde(transparent)]
pub struct CreateExternalParams(#[serde(with = "strict_bytes")] pub Vec<u8>);

#[test]
fn miner_tests() {
    println!("Testing solidity API");

    let mut gas_result: GasResult = vec![];
    let (mut tester, manifest) = setup::setup_tester();

    // Set storagemarket actor
    let state_tree = tester.state_tree.as_mut().unwrap();
    helpers::set_storagemarket_actor(
        state_tree,
        *manifest.code_by_id(builtins::Type::Market as u32).unwrap(),
    )
    .unwrap();
    // Set storagepower actor
    helpers::set_storagepower_actor(
        state_tree,
        *manifest.code_by_id(builtins::Type::Power as u32).unwrap(),
    )
    .unwrap();
    helpers::set_reward_actor(
        state_tree,
        *manifest.code_by_id(builtins::Type::Reward as u32).unwrap(),
    )
    .unwrap();

    let sender: [Account; 1] = tester.create_accounts().unwrap();

    /***********************************************
     *
     * Instantiate Account Actor with a BLS address
     *
     ***********************************************/

    let bls_private_key = bls_signatures::PrivateKey::generate(&mut OsRng);
    let worker = Address::new_bls(&bls_private_key.public_key().as_bytes()).unwrap();

    let state_tree = tester.state_tree.as_mut().unwrap();
    let assigned_addr = state_tree.register_new_address(&worker).unwrap();
    let state = fvm::account_actor::State { address: worker };

    let cid = state_tree
        .store()
        .put_cbor(&state, Code::Blake2b256)
        .unwrap();

    let actor_state = ActorState {
        code: *manifest.get_account_code(),
        state: cid,
        sequence: 0,
        balance: TokenAmount::from_atto(10000),
        delegated_address: Some(worker),
    };

    state_tree.set_actor(assigned_addr, actor_state).unwrap();
    // Instantiate machine
    tester.instantiate_machine(DummyExterns).unwrap();

    let executor = tester.executor.as_mut().unwrap();

    // Try to call "constructor"
    println!("Try to call constructor on storage power actor");

    let message = Message {
        from: SYSTEM_ACTOR_ADDR,
        to: STORAGE_POWER_ACTOR_ADDR,
        gas_limit: 1000000000,
        method_num: 1,
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Implicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    // Try to call "constructor"
    println!("Try to call constructor on storage market actor");

    let message = Message {
        from: SYSTEM_ACTOR_ADDR,
        to: STORAGE_MARKET_ACTOR_ADDR,
        gas_limit: 1000000000,
        method_num: 1,
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Implicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    // Try to call "constructor"
    println!("Try to call constructor on reward actor");

    let message = Message {
        from: SYSTEM_ACTOR_ADDR,
        to: REWARD_ACTOR_ADDR,
        gas_limit: 1000000000,
        params: RawBytes::new(vec![0]), // I have to send the power start value (0)
        method_num: 1,
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Implicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    /**************************
     *
     * Machine instantiated
     *
     **************************/

    println!("Create Miner actor for solidity contract to interact with");

    let constructor_params = CreateMinerParams {
        owner: Address::new_id(103),
        worker,
        window_post_proof_type: fvm_shared::sector::RegisteredPoStProof::StackedDRGWindow32GiBV1,
        peer: vec![1, 2, 3],
        multiaddrs: vec![BytesDe(vec![1, 2, 3])],
    };

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(4),
        gas_limit: 1000000000,
        method_num: 2,
        params: RawBytes::serialize(constructor_params).unwrap(),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    dbg!(&res);
    let exec_return: ExecReturn = RawBytes::deserialize(&res.msg_receipt.return_data).unwrap();

    dbg!(hex::encode(&exec_return.id_address.to_bytes()));

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    println!("Calling init actor (EVM)");

    let evm_bin = setup::load_evm(WASM_COMPILED_PATH);

    let constructor_params = CreateExternalParams(evm_bin);

    let message = Message {
        from: sender[0].1,
        to: EAM_ACTOR_ADDR,
        gas_limit: 1000000000,
        method_num: 4,
        sequence: 1,
        params: RawBytes::serialize(constructor_params).unwrap(),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();

    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let exec_return: Return = RawBytes::deserialize(&res.msg_receipt.return_data).unwrap();

    println!("Calling `change_owner_address`");

    let abi_encoded_call = api_contracts::miner_test::change_owner_addressCall{
        target: 0x66_u64,
        addr: api_contracts::miner_test::FilAddress{
            data: vec![0_u8, 0x66]
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(&sender[0]);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 2,
        params: RawBytes::new(hex::decode(
            // "58A47D41DDD900000000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020066000000000000000000000000000000000000000000000000000000000000"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("change_owner_address".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);
    assert_eq!(hex::encode(res.msg_receipt.return_data.bytes()), "40");

    println!("Calling `get_beneficiary`");

    let abi_encoded_call = api_contracts::miner_test::get_beneficiaryCall{
        target: 0x66_u64,
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 3,
        params: RawBytes::new(hex::decode(
            // "5824B760A3E40000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("get_beneficiary".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_beneficiary = (
        api_contracts::miner_test::ActiveBeneficiary{
            beneficiary: api_contracts::miner_test::FilAddress{
                data: vec![0_u8, 0x67]
            },
            term: api_contracts::miner_test::BeneficiaryTerm{
                quota: api_contracts::miner_test::BigInt{
                    val: fixed_bytes!("").to_vec(),
                    neg: false
                },
                used_quota: api_contracts::miner_test::BigInt{
                    val: fixed_bytes!("").to_vec(),
                    neg: false
                },
                expiration: 0_i64
            }
        },
        api_contracts::miner_test::PendingBeneficiaryChange{
            new_beneficiary: api_contracts::miner_test::FilAddress{
                data: fixed_bytes!("").to_vec(),
            },
            new_expiration: 0_i64,
            new_quota: api_contracts::miner_test::BigInt{
                val: fixed_bytes!("").to_vec(),
                neg: false
            },
            approved_by_beneficiary: false,
            approved_by_nominee: false
        }
    );

    let tmp = api_contracts::miner_test::GetBeneficiaryReturnCall{
        values: expected_beneficiary
    }.abi_encode();

    let abi_encoded_call = vec![vec![0_u8, 0, 0, 0], tmp[8..].to_vec()].concat();

    let temp = api_contracts::cbor_encode(abi_encoded_call.clone());

    dbg!(temp);
    let temp2 =  api_contracts::cbor_encode(abi_encoded_call.clone());
    let cbor_encoded = temp2.as_str();
    let temp = cbor_encoded.replace("00018000", "00020000");
    let cbor_encoded_str = temp.as_str();

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "590360000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded_str
    );

    println!("Calling `change_beneficiary`");
    let abi_encoded_call = api_contracts::miner_test::change_beneficiaryCall{
        target: 0x66_u64,
        params: api_contracts::miner_test::ChangeBeneficiaryParams{
            new_beneficiary: api_contracts::miner_test::FilAddress{
                data: vec![0_u8, 0x66]
            },
            new_expiration: 0_i64,
            new_quota: api_contracts::miner_test::BigInt{
                val: fixed_bytes!("0001").to_vec(),
                neg: false
            },
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(cbor_encoded.as_str());

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 4,
        params: RawBytes::new(hex::decode(
            // "590184FDEDB5B500000000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000C000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020001000000000000000000000000000000000000000000000000000000000000"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("change_beneficiary".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);
    assert_eq!(hex::encode(res.msg_receipt.return_data.bytes()), "40");

    println!("Calling `get_owner`");

    let abi_encoded_call = api_contracts::miner_test::get_ownerCall{
        target: 0x66_u64
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 5,
        params: RawBytes::new(hex::decode(
            // "5824B699AD660000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("get_owner".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_owner = api_contracts::miner_test::GetOwnerReturn{
        owner: api_contracts::miner_test::FilAddress{
            data: vec![0x00_u8, 0x67]
        },
        proposed: api_contracts::miner_test::FilAddress{
            data: vec![0x00_u8, 0x66]
        },
    };
    let abi_encoded_call = api_contracts::miner_test::GetOwnerReturn::abi_encode(&expected_owner);
    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "5901200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020066000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `get_available_balance`");

    let abi_encoded_call = api_contracts::miner_test::get_available_balanceCall{
        target: 0x66_u64
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 6,
        params: RawBytes::new(hex::decode(
            // "5824BEF7AE6D0000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("get_available_balance".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_balance = api_contracts::miner_test::BigInt{
        val: fixed_bytes!("").to_vec(),
        neg: false
    };
    let abi_encoded_call = api_contracts::miner_test::BigInt::abi_encode(&expected_balance);
    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `get_vesting_funds`");

    let abi_encoded_call = api_contracts::miner_test::get_vesting_fundsCall{
        target: 0x66_u64
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 7,
        params: RawBytes::new(hex::decode(
            // "58249A77B3260000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("get_vesting_funds".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let abi_encoded_call = api_contracts::miner_test::encode_vesting_fundsCall{vesting_funds: vec![]}.abi_encode();
    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call[4..].to_vec());

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "5860000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `repay_debt`");

    let abi_encoded_call = api_contracts::miner_test::repay_debtCall{
        target: 0x66_u64
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 8,
        params: RawBytes::new(hex::decode(
            // "5824A66AF3EF0000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("repay_debt".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);
    assert_eq!(hex::encode(res.msg_receipt.return_data.bytes()), "40");

    println!("Calling `confirm_change_worker_address`");

    let abi_encoded_call = api_contracts::miner_test::confirm_change_worker_addressCall{
        target: 0x66_u64
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 9,
        params: RawBytes::new(hex::decode(
            // "58246B58EFC40000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push((
        "confirm_change_worker_address".into(),
        gas_used,
    ));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);
    assert_eq!(hex::encode(res.msg_receipt.return_data.bytes()), "40");

    println!("Calling `get_peer_id`");

    let abi_encoded_call = api_contracts::miner_test::get_peer_idCall{
        target: 0x66_u64
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 10,
        params: RawBytes::new(hex::decode(
            // "5824F7E6CEA30000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("get_peer_id".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_peer_id = api_contracts::miner_test::FilAddress{
        data: vec![1_u8, 2, 3]
    };
    let abi_encoded_call = api_contracts::miner_test::FilAddress::abi_encode(&expected_peer_id);
    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030102030000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `get_multiaddresses`");

    let abi_encoded_call = api_contracts::miner_test::get_multiaddressesCall{
        target: 0x66_u64
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 11,
        params: RawBytes::new(hex::decode(
            // "582434DF79FE0000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("get_multiaddresses".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_multi_addr = api_contracts::miner_test::GetMultiaddrsReturn{
        multi_addrs: vec![
            api_contracts::miner_test::FilAddress{
                data: vec![1_u8, 2, 3]
            }
        ]
    };
    let abi_encoded_call = api_contracts::miner_test::GetMultiaddrsReturn::abi_encode(&expected_multi_addr);
    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030102030000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `change_worker_address`");

    let abi_encoded_call = api_contracts::miner_test::change_worker_addressCall{
        target: 0x66_u64,
        params: api_contracts::miner_test::ChangeWorkerAddressParams{
            new_worker: api_contracts::miner_test::FilAddress{
                data: vec![0_u8, 0x65]
            },
            new_control_addresses: vec![]
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(cbor_encoded.as_str());

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 12,
        params: RawBytes::new(hex::decode(
            // "590104EA3C276600000000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000A00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("change_worker_address".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);
    assert_eq!(hex::encode(res.msg_receipt.return_data.bytes()), "40");

    println!("Calling `is_controlling_address`");

    let abi_encoded_call = api_contracts::miner_test::is_controlling_addressCall{
        target: 0x66_u64,
        addr: api_contracts::miner_test::FilAddress{
            data: vec![0_u8, 0x66]
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
       from: sender[0].1,
       to: Address::new_id(exec_return.actor_id),
       gas_limit: 1000000000,
       method_num: EvmMethods::InvokeContract as u64,
       sequence: 13,
       params: RawBytes::new(hex::decode(
            // "58A4941C532200000000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020066000000000000000000000000000000000000000000000000000000000000"
            cbor_encoded.as_str()
        ).unwrap()),
       ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("is_controlling_address".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_res_bool = false;
    let abi_encoded_call = sol_data::Bool::abi_encode(&expected_res_bool); 

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()),
        // "58200000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    println!("Calling `get_sector_size`");

    let abi_encoded_call = api_contracts::miner_test::get_sector_sizeCall{
        target: 0x66_u64,
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 14,
        params: RawBytes::new(hex::decode(
            // "58249A4671E90000000000000000000000000000000000000000000000000000000000000066"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("get_sector_size".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_sector_size = 0x800000000_u64;
    let abi_encoded_call = sol_data::Uint::<64>::abi_encode(&expected_sector_size); 

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()),
        // "58200000000000000000000000000000000000000000000000000000000800000000"
        cbor_encoded.as_str()
    );

    println!("Calling `change_multiaddresses`");

    let abi_encoded_call = api_contracts::miner_test::change_multiaddressesCall{
        target: 0x66_u64,
        params: api_contracts::miner_test::ChangeMultiaddrsParams{
            new_multi_addrs: vec![
                api_contracts::miner_test::FilAddress{
                    data: vec![0_u8, 0x66]
                }
            ]
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    dbg!(cbor_encoded.as_str());

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 15,
        params: RawBytes::new(hex::decode(
            // "590104383F4AD000000000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020066000000000000000000000000000000000000000000000000000000000000"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("change_multiaddresses".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);
    assert_eq!(hex::encode(res.msg_receipt.return_data.bytes()), "40");

    println!("Calling `change_peer_id`");

    let abi_encoded_call = api_contracts::miner_test::change_peer_idCall{
        target: 0x66_u64,
        newId: api_contracts::miner_test::FilAddress{
            data: vec![0_u8, 0x66]
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 16,
        params: RawBytes::new(hex::decode(
            // "58A4E33B774700000000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020066000000000000000000000000000000000000000000000000000000000000"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("change_peer_id".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);
    assert_eq!(hex::encode(res.msg_receipt.return_data.bytes()), "40");

    println!("Calling `withdraw_balance`");

    let abi_encoded_call = api_contracts::miner_test::withdraw_balanceCall{
        target: 0x66_u64,
        amount: api_contracts::miner_test::BigInt{
            val: fixed_bytes!("0001").to_vec(),
            neg: false
        }
    }.abi_encode();

    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    let message = Message {
        from: sender[0].1,
        to: Address::new_id(exec_return.actor_id),
        gas_limit: 1000000000,
        method_num: EvmMethods::InvokeContract as u64,
        sequence: 17,
        params: RawBytes::new(hex::decode(
            // "58C4B4661C29000000000000000000000000000000000000000000000000000000000000006600000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020001000000000000000000000000000000000000000000000000000000000000"
            cbor_encoded.as_str()
        ).unwrap()),
        ..Message::default()
    };

    let res = executor
        .execute_message(message, ApplyKind::Explicit, 100)
        .unwrap();
    let gas_used = parse_gas(res.exec_trace);
    gas_result.push(("withdraw_balance".into(), gas_used));
    assert_eq!(res.msg_receipt.exit_code.value(), 0);

    let expected_balance = api_contracts::miner_test::BigInt{
        val: fixed_bytes!("").to_vec(),
        neg: false
    };
    let abi_encoded_call = api_contracts::miner_test::BigInt::abi_encode(&expected_balance);
    let cbor_encoded = api_contracts::cbor_encode(abi_encoded_call);

    assert_eq!(
        hex::encode(res.msg_receipt.return_data.bytes()), 
        // "58800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cbor_encoded.as_str()
    );

    let table = testing::create_gas_table(gas_result);
    testing::save_gas_table(&table, "miner");

    table.printstd();
}
