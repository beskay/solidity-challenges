// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEXP {
    function mint(address _to, uint256 _value) external;
}

contract Proxy {
    address private delegate;
    address public owner = msg.sender;
    IEXP public exp;

    constructor(address expAddress, address _delegate) {
        // initialize EXP and delegate contract
        exp = IEXP(expAddress);
        delegate = _delegate;
    }

    function deactiveProxy() external {
        require(msg.sender == owner, "only owner");

        // set delegate to zero address, essentially disabling this contract
        delegate = address(0);

        // mint 1 exp as reward
        exp.mint(msg.sender, 1 ether);
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
