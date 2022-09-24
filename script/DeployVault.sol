// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Vault.sol";
import "../src/Vesting.sol";

contract DeployVault is Script {
    function run() public {
        vm.startBroadcast();

        // deploy Vault & Vesting
        Vesting vesting = new Vesting();
        Vault vault = new Vault(address(vesting));

        // send 0.2 ETH to Vault
        (bool success,) = address(vault).call{value: 0.2 ether}("");
        require(success, "fail");

        vm.stopBroadcast();
    }
}
