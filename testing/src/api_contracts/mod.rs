use cbor_data::{CborBuilder, Encoder};

pub mod account_test;
pub mod address_test;
pub mod market_test;


pub fn cbor_encode(abi_encoded_call: Vec<u8>) -> String {
  let full_str = hex::encode(CborBuilder::default().encode_array(|builder| {
      builder.encode_bytes(abi_encoded_call);
  }));
  let encoded = full_str[2..].to_string(); 
  return encoded;
}