# Challenges

| No  | Contracts                                                                    | Type                                  | Difficulty | Writeup                                                                                 |
| --- | ---------------------------------------------------------------------------- | ------------------------------------- | ---------- | --------------------------------------------------------------------------------------- |
| 1   | [PrivateData.sol](src/PrivateData.sol)                                       | Private data                          | Easy       | [link](https://mirror.xyz/ethernautdao.eth/mxnAUuwRX6h42jubCzF_9-Tbsp14uH_eQ3xyEn4jF7w) |
| 2   | [Wallet.sol](src/Wallet.sol),<br/>[WalletLibrary.sol](src/WalletLibrary.sol) | Low level calls                       | Easy       | [link](https://mirror.xyz/ethernautdao.eth/-rj5iTdt_GTRNS7aIzJBwqp95UGemxIMzNN-m96Io8Y) |
| 3   | [VNFT.sol](src/VNFT.sol)                                                     | Weak RNG,<br/> Smart contract minting | Medium     | [VNFT.md](writeups/VNFT.md)                                                             |
| 4   | [EtherWallet.sol](src/EtherWallet.sol)                                       | Signature Malleability                | Medium     | [EtherWallet.md](writeups/EtherWallet.md)                                               |
| 5   | [Vault.sol](src/Vault.sol),<br/>[Vesting.sol](src/Vesting.sol)               | Low level calls                       | Medium     | [Vault.md](writeups/Vault.md)                                                           |
| 6   | Staking (coming soon)                                                        | TBA                                   | TBA        | soon                                                                                    |

## Install

Install [Foundry](https://github.com/gakonst/foundry) if you haven't already.

```
git clone git@github.com:beskay/solidity-challenges.git
git submodule update --init --recursive  ## initialize submodule dependencies
```

## Tests and Exploits

See [/test](./test/) for an example setup and exploit test of all challenges. In order to test a single contract, run

```
forge test --match-contract <CONTRACT_NAME>
```

E.g. `forge test --match-contract PrivateTest` to run the test for `PrivateData.sol`.

See [/script/exploits](./script/exploits/) for example exploit scripts to hack the deployed contracts on the goerli testnet

## Deploy and verify

To deploy and verify the contracts, run

```
forge script script/<deploy_script>.sol:<contract_name> --rpc-url $RPC_URL --broadcast --verify --private-key $PK --etherscan-api-key $ETHERSCAN_API -vvv
```

Note that ETH_RPC_URL, ETHERSCAN_API and PK has to be set

```
export ETH_RPC_URL=<your_eth_rpc_url>
export ETHERSCAN_API=<your_etherscan_apikey>
export PK=<your_private_key>
```

Or create a .env file and load the variables with `source .env`
