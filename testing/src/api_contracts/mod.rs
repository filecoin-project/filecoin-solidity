use cbor_data::{CborBuilder, Encoder};

pub mod account_test;
pub mod address_test;
pub mod bigints_test;
pub mod cbor_decode_test;
pub mod datacap_test;
pub mod deserialize_params_test;
pub mod market_cbor_test;
pub mod market_test;
pub mod miner_test;
pub mod power_test;
pub mod precompiles_test;
pub mod send_test;
pub mod verifreg_test;

pub fn cbor_encode(abi_encoded_call: Vec<u8>) -> String {
  let full_str = hex::encode(CborBuilder::default().encode_array(|builder| {
      builder.encode_bytes(abi_encoded_call);
  }));
  let encoded = full_str[2..].to_string(); 
  return encoded;
}