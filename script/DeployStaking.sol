// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Staking.sol";
import "../src/tokens/MockERC20.sol";
import "../src/tokens/RewardToken.sol";
import "../src/tokens/StakingToken.sol";

contract DeployStaking is Script {
    RewardToken internal rtk;
    StakingToken internal stk;
    Staking internal staking;
    MockERC20 internal token;

    // 3 months
    uint256 duration = 86400 * 7 * 12;

    function run() public {
        vm.startBroadcast();

        // deploy erc20s for rewardtoken
        token = new MockERC20();

        // deploy reward token: Name, Symbol, lpaddress
        rtk = new RewardToken("RewardToken", "RTK", vm.addr(100));

        // add mock erc20 as rewardtoken for RTK (to increase gas)
        rtk.addReward(address(token), msg.sender, duration);

        // deploy staking token + staking contract
        stk = new StakingToken();
        staking = new Staking(address(stk));

        // add rewardToken as reward for staking contract
        staking.addReward(address(rtk), msg.sender, duration);
        rtk.mint(msg.sender, 10 * 10 ** 9 * 10 ** 18);
        rtk.approve(address(staking), 2 ** 256 - 1);
        staking.notifyRewardAmount(address(rtk), 1000_000 * 10 ** 18);

        vm.stopBroadcast();
    }
}
