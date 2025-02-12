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
        if (user[_index].user != address(0)) {
            require(
                block.timestamp < user[_index].timelimit
            );
            require(user[_index].user != msg.sender);
        }
        user[_index].user = msg.sender;
        user[_index].timelimit = block.timestamp + 24 hours ;
    }

    // function draw() external {} ;

    // function claim() external {} ;

    receive() external payable {}
}
