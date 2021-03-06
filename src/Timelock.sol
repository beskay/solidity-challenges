// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * Timelock v1
 * Users can lock up their ETH by calling setReleaseDate
 * and unlock it via unlockFunds, if block.timestamp > releaseDate
 * This contract is only deployed once and all ColdStorage proxy
 * contracts access it via delegatecall
 */
contract Timelock {
    address public owner;
    uint256 public releaseDate;
    bool public locked;

    function setReleaseDate(uint256 date) external {
        // only possible to increase lock
        if (locked) {
            require(date > releaseDate, "You cant decrease the lock time!");
        } else locked = true;

        releaseDate = date;
    }

    function unlockFunds() external {
        require(block.timestamp > releaseDate, "Not yet");

        locked = false;
    }
}
