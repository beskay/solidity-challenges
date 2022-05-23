// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Timelock {
    address public owner;
    uint256 public releaseDate;
    bool public locked;

    receive() external payable {}

    function setReleaseDate(uint256 date) external {
        // only possible to increase lock
        if (locked) {
            require(date > releaseDate, "You cant decrease the lock time!");
        } else locked = true;

        releaseDate = date;
    }

    function withdraw() external {
        require(block.timestamp > releaseDate, "Cant withdraw yet");
        require(msg.sender == owner, "Only owner");

        payable(msg.sender).transfer(address(this).balance);
    }
}
