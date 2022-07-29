// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract StakingToken is ERC20, Ownable {
    constructor(address stakingContract) ERC20("RewardToken", "RTK") {
        // mint 1 million tokens to staking contract
        // UPDATE THIS TO NOTIFY REWARD AMOUNT ::::
        _mint(stakingContract, 10 * 10**6 * 10**18);
    }
}
