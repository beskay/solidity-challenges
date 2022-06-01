# Challenges

| No  | Contracts                                                                    | Type                                  | Difficulty | Explanation |
| --- | ---------------------------------------------------------------------------- | ------------------------------------- | ---------- | ----------- |
| 1   | [PrivateData.sol](src/PrivateData.sol)                                       | Private data                          | Easy       | soon        |
| 2   | [Wallet.sol](src/Wallet.sol),<br/>[WalletLibrary.sol](src/WalletLibrary.sol) | Low level calls                       | Easy       | soon        |
| 3   | [ColdStorage.sol](src/ColdStorage.sol),<br/>[Timelock.sol](src/Timelock.sol) | Low level calls                       | Medium     | soon        |
| 4   | [EtherWallet.sol](src/EtherWallet.sol)                                       | Signature Malleability                | Medium     | soon        |
| 5   | [VNFT.sol](src/VNFT.sol)                                                     | Weak RNG,<br/> Smart contract minting | Medium     | soon        |

## Install

Install [Foundry](https://github.com/gakonst/foundry) if you haven't already.

```
git clone git@github.com:beskay/solidity-challenges.git
git submodule update --init --recursive  ## initialize submodule dependencies
```

## Deploy and verify

To deploy the contracts, run

```
forge script ./scripts/deploy.sol --tc Deploy --rpc-url $ETH_RPC_URL --broadcast --private-key $PK -vvv
```

Note that ETH_RPC_URL and PK has to be set

```
export ETH_RPC_URL=<your_etherscan_apikey>
export PK=<your_private_key>
```

To verify the deployed contracts, see [here](https://book.getfoundry.sh/forge/deploying.html?highlight=verify#verifying-a-pre-existing-contract)
