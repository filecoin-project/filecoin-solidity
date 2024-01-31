use fvm::executor::{ApplyKind, ApplyRet, Executor};
use cid::Cid;
use fvm::machine::Manifest;
use fvm_ipld_blockstore::MemoryBlockstore;
use fvm_integration_tests::tester::Tester;
use fvm_shared::state::StateTreeVersion;
use fvm_shared::version::NetworkVersion;
use fvm_integration_tests::bundle;
use fvm_ipld_encoding::CborStore;
use fvm_integration_tests::dummy::DummyExterns;
use fvm_ipld_encoding::tuple::*;

// use fvm::gas::Gas;
// use fvm::trace::ExecutionEvent;
// use fvm_integration_tests::bundle;
// use fvm_integration_tests::dummy::DummyExterns;
// use fvm_integration_tests::tester::{Account, Tester};
// use fvm_ipld_blockstore::MemoryBlockstore;
// use fvm_ipld_encoding::tuple::*;
// use fvm_ipld_encoding::RawBytes;
// use fvm_shared::address::Address;
// use fvm_shared::crypto::signature::SECP_SIG_LEN;
// use fvm_shared::econ::TokenAmount;
// use fvm_shared::error::ExitCode;
// use fvm_shared::message::Message;
// use fvm_shared::state::StateTreeVersion;
// use fvm_shared::version::NetworkVersion;
// use fvm_test_actors::wasm_bin::GAS_CALIBRATION_ACTOR_BINARY;
// use lazy_static::lazy_static;
// use num_traits::Zero;
// use serde::Serialize;

pub fn setup_tester() -> (Tester<MemoryBlockstore, DummyExterns>, Manifest) {
    let bs = MemoryBlockstore::default();
    // let actors = std::fs::read("./builtin-actors/output/builtin-actors-mainnet.car")
    //     .expect("Unable to read actor devnet file");
    // let bundle_root = bundle::import_bundle(&bs, &actors).unwrap();
    let bundle_root = bundle::import_bundle(&bs, actors_v12::BUNDLE_CAR).unwrap();

    let (manifest_version, manifest_data_cid): (u32, Cid) =
        bs.get_cbor(&bundle_root).unwrap().unwrap();
    let manifest = Manifest::load(&bs, &manifest_data_cid, manifest_version).unwrap();

    let tester =
        Tester::new(NetworkVersion::V21, StateTreeVersion::V5, bundle_root, bs).unwrap();

    return (tester, manifest)
}

pub fn load_evm(path: &str) -> Vec<u8> {
    let wasm_path = std::env::current_dir()
        .unwrap()
        .join(path)
        .canonicalize()
        .unwrap();
    let evm_hex = std::fs::read(wasm_path).expect("Unable to read file");

    hex::decode(evm_hex).unwrap()
}