# Solidity challenge Staking.sol

## The objective

According to [that](https://twitter.com/EthernautDAO/status/1571136905021952001) tweet the goal is to "stop" the contract, which means we have to set the contract to paused.

## Overview

Contract `Staking.sol` is deployed at [0x805f...1e8b](https://goerli.etherscan.io/address/0x805f02142680f853a9c0e5d5d6f49aec28c31e8b). Its a slightly modified version of contract [MultiRewards](https://github.com/curvefi/multi-rewards/blob/master/contracts/MultiRewards.sol) from Curve.

It inherits from `Pausable.sol`, which implements an emergency stop mechanism that can be triggered by an authorized account. All functions with modifier `whenNotPaused` will be disabled when `paused == true`. In case of `Staking.sol` function `stake(uint256 amount)` will be disabled, preventing new users from staking their tokens.

## Exploit

The only way to set the contract to paused is to let the sub-call in function `getReward()` fail:

```solidity
(bool success,) =
    address(_rewardsToken).call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, reward));
if (!success) {
    _pause();
    return;
}
```

Letting this call fail is easy: Simply dont provide enough gas, which causes an out-of-gas error. Theres a problem though: If the sub-call fails because no gas is left, the whole transaction should revert too, meaning that its impossible to set the contract to paused, right?

### The 1/64 Rule

Since [EIP-150](https://eips.ethereum.org/EIPS/eip-150), a caller can only give to a callee an amount of gas no greater than

```
gas available - (1/64 * gas available)
```

Which means that 1/64 of the amount of gas forwarded to the callee remains in the caller contract, e.g. if 64k gas is available only 63k will be forwarded to the callee and 1k remains in the parent contract (the caller contract).

In order to successfully set the contract to paused, the sub-call to `RewardToken` has to use so much gas that the remaining 1/64 is enough to sucessfully execute `_pause()`. Luckily, the `transfer` function of contract `RewardToken` is extremely inefficient (what a coincidence) -- it is using over 500k gas, so at least 8k gas remains in the parent contract, enough to pause the contract.

To exploit the contract we have to set the gas limit of our tx to just the right amount, not enough to successfully execute `transfer` from `RewardToken`, but still enough that the whole transaction won't fail. After some trial and error it is found that the amount needed is around 680k gas, see [this](https://goerli.etherscan.io/tx/0xe62dc21f23b5822a53655cfdcb88eb2b8966e458a8b4d00e8ad7c4ea221fe9d8) transaction.

This exploit is called a insufficient gas griefing exploit, it causes grief -- new users cant stake and therefore wont be able to earn any rewards.

## Takeaways

`require(success)` after each sub-call prevents this vulnerability:

```solidity
(bool success,) =
    address(_rewardsToken).call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, reward));
require(success, "call failed!");
```

## Further information

- [Insufficient Gas Griefing](https://swcregistry.io/docs/SWC-126)
- [Ethereum gas dangers](https://ronan.eth.link/blog/ethereum-gas-dangers/)
