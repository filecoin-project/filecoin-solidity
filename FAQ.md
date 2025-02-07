# **Filecoin Solidity Library FAQ**  

This FAQ provides guidance on using the **Filecoin Solidity Library**, answering common developer questions about **interacting with Filecoin actors, handling serialization, managing balances, and working with allowances**.  

For up-to-date documentation and the latest version of the library, visit the **[official repository](https://github.com/filecoin-project/filecoin-solidity).**  

---

## **General Usage**  

### What is the Filecoin Solidity Library?  
The **Filecoin Solidity Library** provides EVM-compatible smart contracts that allow developers to interact with **Filecoin actors**, making it easier to integrate with the Filecoin blockchain’s **storage market, miner actors, verified registry, and more**.  

### Where can I find the latest version of the library?  
The official repository is available at:  
📌 [Filecoin Solidity Repository](https://github.com/filecoin-project/filecoin-solidity)  

---

## **Serialization and Address Handling**  

### What is the difference between `serializeAddress` and `serializeBytes`?  
The `serializeAddress` function is implemented in two variations:  

1. **`BytesCBOR.serializeAddress`** – Behaves identically to `serializeBytes`, encoding a byte array without additional validation.  
2. **`FilecoinCBOR.serializeAddress`** – Specifically designed to serialize a **CommonTypes.FilAddress**.  

Both functions **encode** addresses, but neither **validates** that the input represents a valid Filecoin address. Developers should ensure they pass correctly formatted addresses before serialization.  

### How should buffer allocation be handled in serialization?  
Efficient buffer allocation helps optimize **gas costs**. When working with serialization:  
- Always **precompute the expected buffer size** to avoid unnecessary resizing.  
- Ensure all **fields are accounted for** in capacity calculations.  
- Validate serialized output against expected structures to avoid inconsistencies.  

By following these practices, developers can ensure **efficient** and **gas-optimized** serialization.  

---

### **How should zero values be handled in `BigInt`?**

In the **Filecoin Solidity Library**, a `BigInt` can represent zero in two ways:

1. **An empty `BigInt`** (no sign or value field) is interpreted as **zero**.
2. **A `BigInt` with a value field set to `0`** is also considered **zero**, regardless of the sign field.

Developers should ensure that:
- **Both representations of zero** are handled **consistently** in serialization and deserialization.
- Functions processing `BigInt` correctly **interpret the sign and value fields**, ensuring that a zero value does not lead to unintended behavior.

---

## **Allowance and Token Transfers**  

### How does `transferFrom` handle allowances in the Filecoin Solidity Library?  
The library follows an **allowance-based transfer model**, similar to Ethereum’s ERC-20 standard, but developers should verify:  
- Whether **allowances decrease** after transactions when set to `type(uint256).max`.  
- The **exact behavior of `transferFrom`** in different execution contexts within Filecoin’s FVM.  

Checking allowance changes after transactions ensures **proper integration** when handling delegated token transfers.  

### What happens if `withdrawBalance` or `addBalance` is called with an amount exceeding available funds?  
- **`withdrawBalance`**: If the requested withdrawal exceeds the user’s balance, the function **withdraws the maximum available amount**.  
- **`addBalance`**: If the specified amount **exceeds available funds**, the transaction **fails** rather than partially completing.  

Understanding these behaviors helps ensure **predictable fund management** within contracts.  

---

## **Filecoin Actor Calls**  

### What happens when querying Filecoin actors for non-existent data?  
Different Filecoin actor calls handle missing data in distinct ways:  
- Some calls **return success with an empty entry** if the queried data does not exist.  
- Others **return an error code**, requiring explicit error handling.  

Developers should check the expected behavior of each Filecoin actor when integrating their contracts.  

### How does `publishStorageDeals` handle invalid signatures?  
If a **signature is invalid**, the function **does not revert the entire transaction**. Instead:  
- Valid deals **continue processing** as expected.  
- Invalid deals **are skipped** but do not trigger a contract revert.  
- If **all deals** are invalid, an **error code is returned** rather than a full transaction failure.  

Developers should **always check transaction results** after execution to verify deal statuses.  

### Can `GetDealDataCommitmentReturn` return large amounts of data?  
Yes. Depending on **commitment size**, return data may be **substantial**.  
- Contracts handling large commitments should **optimize memory usage**.  
- Consider **potential Solidity memory limitations** when working with extensive data sets.  

### What happens if `changeOwnerAddress` is called with the same address?  
If **no existing ownership change proposal** exists, calling `changeOwnerAddress` with the same owner **has no effect**.  

---

## **Miner API**  

### How does the Filecoin network handle slashed or terminated miners?  
- **Slashed miners** remain in the network but may have **restricted functionality**.  
- Some API calls **return data for slashed miners**, while others **exclude them**.  

When integrating with **miner-related functions**, confirm whether specific calls include or omit terminated miners.  

### Is a multi-address operator required when calling `CreateMiner`?  
No. If no **multi-address operator** is provided, the **owner automatically assumes control** of the miner.  

---

## **Power API**  

### Does `minerCount` include terminated miners?  
- **`minerConsensusCount`** includes **only active miners** that meet **consensus power requirements**.  
- **`minerCount`** returns **all miners ever created**, including terminated ones.  

### Can `CreateMiner` be called without specifying a multi-address?  
Yes. If a **multi-address is not provided**, the **owner automatically takes control**.  

---

## **Security and Error Handling**  

### Should I use `require` or `assert` for error handling?  
In Solidity:  
- **`require`** is used for **expected errors** (e.g., invalid user input).  
- **`assert`** is used for **internal invariants** (unexpected conditions).  

For **consistent and predictable error handling**, developers should **use `require` where possible**.  

### Can Filecoin precompiles hold native ETH?  
This behavior is **not explicitly defined**. Developers should verify:  
- Whether **precompile accounts** can hold **native ETH balances**.  
- How balances are tracked and **retrieved**.  

Until further clarification, **assume precompiles do not store ETH** unless explicitly stated.  

---

## **Additional Resources**  

### Where can I find more information on Filecoin Solidity development?  
📌 **Official Filecoin Solidity Repository:**  
[https://github.com/filecoin-project/filecoin-solidity](https://github.com/filecoin-project/filecoin-solidity)  

📌 **Filecoin Documentation:**  
[https://docs.filecoin.io](https://docs.filecoin.io)  

📌 **FVM Developer Resources:**  
[https://fvm.filecoin.io](https://fvm.filecoin.io)  
