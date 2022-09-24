// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/VNFT.sol";

contract DeployVNFT is Script {
    function run() public {
        vm.startBroadcast();

        // deploy vnft
        VNFT vnft = new VNFT();

        // import PK from environment variables
        // foundrys conversion to uint doesnt work, so convert the PK to a decimal number beforehand
        string memory PK = "PK_UINT";
        uint256 privateKey = vm.envUint(PK);

        // sign message
        bytes32 hash = keccak256("EthernautDAO");
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(privateKey, keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)));
        bytes memory signature = abi.encodePacked(r, s, v);

        vnft.whitelistMint(msg.sender, 1, hash, signature);

        vm.stopBroadcast();
    }
}
