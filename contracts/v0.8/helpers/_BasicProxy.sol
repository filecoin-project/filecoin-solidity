pragma solidity ^0.8.17;

contract _BasicProxy {
    //note: constants are not in storage
    uint constant S_OFFSET = 5;
    //storage:
    uint[S_OFFSET] _notUsed;
    address public delegate;
    bool public called;

    function upgradeDelegate(address newDelegateAddress) public {
        delegate = newDelegateAddress;
    }

    fallback() external {
        called = true;
        assembly {
            let _target := sload(S_OFFSET)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 {
                revert(0, 0)
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

contract _BasicProxyFactory {
    address[] public proxies;
    bool[] public proxyOccupied;

    address public verifRegProxy;
    address public dataCapProxy;

    constructor() {
        verifRegProxy = address(new _BasicProxy());
        dataCapProxy = address(new _BasicProxy());

        for (uint i = 0; i < 10; ++i) {
            deployProxy();
        }
    }

    function deployProxy() public {
        _BasicProxy bp = new _BasicProxy();

        proxies.push(address(bp));
        proxyOccupied.push(false);
    }

    function getFirstAvailableProxy() public view returns (address, uint) {
        for (uint i = 0; i < proxies.length; ++i) {
            if (proxyOccupied[i] == false) {
                return (proxies[i], i);
            }
        }

        return (address(0), 0);
    }

    function occupyProxy(uint i) public {
        require(i < proxies.length, "ERR: Proxy index out of bounds!");
        // require(proxyOccupied[i] == false, "ERR: Proxy already occupied!");
        proxyOccupied[i] = true;
    }

    function getProxyCount() public view returns (uint) {
        return proxies.length;
    }
}
