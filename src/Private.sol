// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEXP {
    function mint(address _to, uint256 _value) external;
}

contract Private {
    IEXP public exp;

    uint256 public constant NUM = 1337;
    address public owner = address(0);
    bytes32[5] private randomData;
    mapping(address => uint256) public addressToKeys;
    uint256 private secretKey;
    bool public exploited;

    constructor(address expAddress, string memory seed) {
        // initialize EXP contract
        exp = IEXP(expAddress);

        // create a random number and store it in a private variable
        secretKey = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    seed
                )
            )
        );
    }

    function takeReward(uint256 key) public {
        // only a person knowing the secretKey is allowed to take rewards
        require(key == secretKey, "Not allowed!");
        require(!exploited, "Can only exploit once!");

        // set exploited to true to prevent reentrancy
        exploited = true;

        exp.mint(msg.sender, 1 ether);
    }
}
