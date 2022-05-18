// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PrivateData {
    uint256 public constant NUM = 1337;
    address public owner;
    bytes32[5] private randomData;
    mapping(address => uint256) public addressToKeys;
    uint128 private a;
    uint128 private b;
    uint256 private secretKey;

    event OwnershipTaken(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;

        // create a random number and store it in a private variable
        secretKey = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp)
            )
        );
    }

    function takeOwnership(uint256 key) public {
        // only a person knowing the secretKey is allowed to take ownership
        require(key == secretKey, "Not allowed!");

        address oldOwner = owner;
        owner = msg.sender;

        emit OwnershipTaken(oldOwner, msg.sender);
    }
}
