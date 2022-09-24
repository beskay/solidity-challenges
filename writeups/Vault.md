# Solidity challenge Vault.sol

## The objective

The same as in previous challenges: Steal the ether in the contract

## Overview

[Vault.sol](https://goerli.etherscan.io/address/0xbbcf8b480f974fa45adc09f102496edc38cb3a6c) serves as a proxy contract for [Vesting.sol](https://goerli.etherscan.io/address/0xf4755e3d2ca9cd6858999a0696ab8e1c96434edc). It is possible to deposit Ether, but theres no function to withdraw it. All deposited Ether follows the vesting schedule defined in the Vesting contract.

`Vault.sol` incorporates function `execute`, which allows arbitrary calls to contracts, and internal function `_delegate`, which is called via the fallback function.

## Exploit

The exploit is based on storage collision, if contract A calls contract B via `delegatecall`, the code of contract B writes to storage of contract A.

In our case `Vault.sol` delegatecalls to `Vesting.sol`, so `Vesting.sol` accesses the storage of `Vault.sol`.

If we take a look at the storage layout of both contracts, we immediately see whats wrong:

```
|Vault.sol           |Vesting.sol              |
|--------------------|-------------------------|
|address delegate    |address beneficiary      | <== Storage collision!
|address owner       |uint256 duration         | <== Storage collision!
```

To take ownership of `Vault.sol`, we have to call function `setDuration` in `Vesting.sol` via delegatecall from `Vault.sol`. This will overwrite the `owner` variable. However, theres one small obstacle: `duration` is of type uint256, but the `owner` variable in `Vault.sol` is an address (obviously).

We need to convert our address to an unsigned integer, this is done pretty easily, since addresses are just hexadecimal numbers:

```solidity
// convert address of attacker to uint256
uint256 duration = uint256(uint160(attackerEOA));
```

The attacker address used has to have a higher decimal value than the current owner, because of the require statement in setDuration:

```solidity
require(durationSeconds > duration, "You cant decrease the vesting time!");
```

Remember, when we use `delegatecall`, we read/write from the storage of `Vault.sol`, so the value of `duration` is actually the `owner` of `Vault.sol`.

We have to bypass the `onlyAuth` modifier of function `_delegate`. We can do this by calling `execute(address, payload)`. `Payload` has to be the function signature of `setDuration(uint256)`. Since `Vault.sol` doesnt implement function `setDuration(uint256)`, the fallback function will be executed, which delegates the call to our Vesting contract

```solidity
IVAULT(vault).execute(address(vault), abi.encodeWithSignature("setDuration(uint256)", duration));
```

`attackerEOA` should be the owner of the Vault contract now. Last thing to do is update the delegate to an attacker contract which withdraws all ETH:

```solidity
IVAULT(vault).upgradeDelegate(address(attackContract));
(bool success,) = address(vault).call(abi.encodeWithSignature("withdraw()"));
```

Code of attacker contract:

```solidity
contract Attacker {
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
```

Thats it!

See [ExploitVault.sol](../script/exploits/ExploitVault.sol) for full code.

## Further information

- [Vault.t.sol](../test/Vault.t.sol) test script setting up and exploiting the contract
- [More info](https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#unstructured-storage-proxies) to storage collisions
- [Infographic](https://twitter.com/beskay0x/status/1504232058566197250/photo/1) to understand execution context in delegatecalls better
