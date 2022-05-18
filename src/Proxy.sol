// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Proxy {
    address private delegate;
    address public owner;

    event ProxyDeactivated(address indexed from);

    constructor(address _delegate) {
        owner = msg.sender;
        // initialize delegate contract
        delegate = _delegate;
    }

    function deactiveProxy() external {
        require(msg.sender == owner, "only owner");

        // set delegate to zero address, essentially disabling this contract
        delegate = address(0);

        emit ProxyDeactivated(msg.sender);
    }

    fallback() external {
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(
                gas(),
                _target,
                0x0,
                calldatasize(),
                0x0,
                0
            )
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
