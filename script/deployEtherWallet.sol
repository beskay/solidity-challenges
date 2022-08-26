// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/EtherWallet.sol";

contract DeployEtherWallet is Script {
    function run() public {
        vm.startBroadcast();

        // deploy etherwallet
        EtherWallet etherwallet = new EtherWallet{value: 0.01 ether}();

        // import PK from environment variables
        // foundrys conversion to uint doesnt work, so convert the PK to a decimal number beforehand
        string memory PK = "PK_UINT";
        uint256 privateKey = vm.envUint(PK);

        // sign message
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n32");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

        // call withdraw to enable exploit
        bytes memory signature = abi.encodePacked(r, s, v);
        etherwallet.withdraw(signature);

        // send ether again
        (bool sent, ) = address(etherwallet).call{value: 0.2 ether}("");
        require(sent, "Failed to send Ether");

        vm.stopBroadcast();
    }
}
