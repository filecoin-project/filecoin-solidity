pragma solidity ^0.8.17;

import "../types/MarketTypes.sol";
import "../types/CommonTypes.sol";
import "../utils/FilAddresses.sol";
import "../utils/FilAddressIdConverter.sol";

import "../cbor/MarketCbor.sol";

contract MarketHelper {
    function serialize_deal_proposal(MarketTypes.DealProposal memory dealProposal) public pure returns (bytes memory) {
        return MarketCBOR.serializeDealProposal(dealProposal);
    }

    function get_address_from_id(uint64 id) public pure returns (CommonTypes.FilAddress memory) {
        return FilAddresses.fromActorID(id);
    }
}
