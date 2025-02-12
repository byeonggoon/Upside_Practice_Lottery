// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

contract Lottery {
    struct UserInfo {
        address user;
        uint256 timelimit;
    }
    mapping(uint256 => UserInfo) public user;

    function buy(uint256 _index) external payable {
        require(msg.value >= 0.1 ether && msg.value % (0.1 ether) == 0);
        console.log("time", block.timestamp, user[_index].timelimit);
        console.log(user[_index].timelimit < block.timestamp);

        if (user[_index].timelimit <= block.timestamp) {
            user[_index].user = msg.sender;
            user[_index].timelimit = block.timestamp;
        } else {
            revert();
        }
        user[_index].user = msg.sender;
        user[_index].timelimit = block.timestamp + 24 hours - 1;
        console.log(" msg.sender", msg.sender);
    }

    // function draw() external {} ;

    // function claim() external {} ;

    receive() external payable {}
}
