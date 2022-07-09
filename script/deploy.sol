// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/PrivateData.sol";
import "../src/Wallet.sol";
import "../src/WalletLibrary.sol";
import "../src/ColdStorage.sol";
import "../src/Timelock.sol";
import "../src/EtherWallet.sol";
import "../src/VNFT.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();

        // deploy privatedata
        PrivateData privatedata = new PrivateData("Test");

        // deploy wallet & walletlibrary
        address[] memory _owners = new address[](3);
        _owners[0] = address(0x89d8632bc8020a7ddd540E6D9B118Aa9EC19af27);
        _owners[1] = address(0x8a5722860c6691F2a25d141D73e678bF1078aac3);
        _owners[2] = vm.addr(3);
        WalletLibrary walletLibrary = new WalletLibrary();
        Wallet wallet = new Wallet(address(walletLibrary), _owners, 2);

        // deploy coldstorage & timelock
        Timelock lock = new Timelock();
        ColdStorage coldstorage = new ColdStorage(address(lock));

        // deploy etherwallet
        EtherWallet etherwallet = new EtherWallet();

        // deploy vnft
        VNFT vnft = new VNFT();

        vm.stopBroadcast();
    }
}
