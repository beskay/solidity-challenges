// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/PrivateData.sol";

contract DeployPrivate is Script {
    function run() public {
        vm.startBroadcast();

        // deploy privatedata
        new PrivateData("Test");

        vm.stopBroadcast();
    }
}
