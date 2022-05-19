// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Timelock {
    address public delegate;
    uint256 releaseDate;
    address public owner;
    bool locked;

    // only send ETH via delegatecall from proxy, else it is lost
    receive() external payable {}

    function setReleaseDate(uint256 date) external {
        require(!locked);
        locked = true;
        releaseDate = date;
    }

    function withdraw() external {
        require(block.timestamp > releaseDate, "Cant withdraw yet");
        require(msg.sender == owner, "Only owner");

        payable(msg.sender).transfer(address(this).balance);
    }
}
