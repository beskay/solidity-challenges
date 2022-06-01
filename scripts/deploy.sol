// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {PrivateData} from "../src/PrivateData.sol";
import {Wallet} from "../src/Wallet.sol";
import {WalletLibrary} from "../src/WalletLibrary.sol";
import {ColdStorage} from "../src/ColdStorage.sol";
import {Timelock} from "../src/Timelock.sol";
import {EtherWallet} from "../src/EtherWallet.sol";
import {VNFT} from "../src/VNFT.sol";

contract Deploy is Test {
    // Contracts
    PrivateData internal privatedata;
    WalletLibrary internal walletLibrary;
    Wallet internal wallet;
    ColdStorage internal coldstorage;
    Timelock internal lock;
    EtherWallet internal etherwallet;
    VNFT internal vnft;

    function run() public {
        vm.startBroadcast();

        // deploy privatedata
        privatedata = new PrivateData();

        // deploy wallet & walletlibrary
        address[] memory _owners = new address[](3);
        _owners[0] = vm.addr(1);
        _owners[1] = vm.addr(2);
        _owners[2] = vm.addr(3);
        walletLibrary = new WalletLibrary();
        wallet = new Wallet(address(walletLibrary), _owners, 2);

        // deploy coldstorage & timelock
        lock = new Timelock();
        coldstorage = new ColdStorage(address(lock));

        // deploy etherwallet
        etherwallet = new EtherWallet();

        // deploy vnft
        vnft = new VNFT();

        vm.stopBroadcast();
    }
}
