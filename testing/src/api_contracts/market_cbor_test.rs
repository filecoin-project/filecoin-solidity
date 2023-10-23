use alloy_sol_types::{sol, SolType};

sol!{

    struct BigInt {
        bytes val;
        bool neg;
    }

    function bigIntEqual(BigInt memory n1, BigInt memory n2) internal pure {}
      
    function testDealProposalSerDes() public view {}
}