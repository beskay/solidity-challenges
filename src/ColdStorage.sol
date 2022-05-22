// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ColdStorage {
    address public delegate;
    address public owner;

    constructor(address _imp) {
        owner = msg.sender;
        delegate = _imp;
    }

    function _delegate(address _imp) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch space at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // delegatecall the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let success := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            // copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch success
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function upgradeDelegate(address newDelegateAddress) public {
        require(msg.sender == owner);
        delegate = newDelegateAddress;
    }

    fallback() external payable {
        if (msg.data.length > 0) _delegate(delegate);
    }
}
