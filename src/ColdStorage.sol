// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * General purpose cold storage contract
 * Implements a call and delegatecall function
 * delegate is a timelock contract, where its possible
 * to lock up your ETH for a given duration, basically
 * forcing you to hodl
 */
contract ColdStorage {
    address public delegate;
    address public owner;

    event Deposit(address _from, uint256 value);
    event DelegateUpdated(address oldDelegate, address newDelegate);

    constructor(address _imp) {
        owner = msg.sender;
        delegate = _imp;
    }

    modifier onlyAuth() {
        require(
            msg.sender == owner || msg.sender == address(this),
            "No permission"
        );
        _;
    }

    fallback() external payable {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
        else if (msg.data.length > 0) _delegate(delegate);
    }

    function execute(address _target, bytes memory payload)
        external
        returns (bytes memory)
    {
        (bool success, bytes memory ret) = address(_target).call(payload);
        require(success, "failed");
        return ret;
    }

    function upgradeDelegate(address newDelegateAddress) external {
        require(msg.sender == owner);
        address oldDelegate = delegate;
        delegate = newDelegateAddress;

        emit DelegateUpdated(oldDelegate, newDelegateAddress);
    }

    function _delegate(address _imp) internal onlyAuth {
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
}
