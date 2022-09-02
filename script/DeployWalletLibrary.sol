// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Wallet.sol";
import "../src/WalletLibrary.sol";

contract DeployWalletLibrary is Script {
    function run() public {
        vm.startBroadcast();

        // deploy wallet & walletlibrary
        address[] memory _owners = new address[](3);
        _owners[0] = address(0x89d8632bc8020a7ddd540E6D9B118Aa9EC19af27);
        _owners[1] = address(0x8a5722860c6691F2a25d141D73e678bF1078aac3);
        _owners[2] = vm.addr(3);
        WalletLibrary walletLibrary = new WalletLibrary();

        new Wallet(address(walletLibrary), _owners, 2);

        vm.stopBroadcast();
    }
}
