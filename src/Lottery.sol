// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
contract Lottery {
    /**
    Lottery
    24시간동안 buy ,24시간동안 추첨 및 클레임 

    function buy(number) 
    같은 넘버는 24시간동안 유지. 24시간 지나면 ㅃ2
    mapping(uint256[] => UserInfo) public user;
    저 number

    처음 24시간 buy 그다음 24시간 draw and claim 반복 

    phase가 홀수 => BUY
    phase가 짝수 => draw and claim 

    처음 constructor 만들때 phase 1시작. 
    그 이후로 buy하면 phase 1안에 계속 들어가고 .
    같은 phase에서 같은 숫자 buy하면 revert 

    constructor() {
        phase[0] = block.timestamp + 24 hours;
    }

    if(block.timestamp > phase[0]){
        phase[i+1] = phase[i] + 24 hours;
    }

    
    buy처음하면 24 hour시작. 
    그 이후 24 시간동안 draw, claim 안됨. 
    draw하고나서 claim가능 
    draw전에는 claim불가. 
    claim까지 끝나고 다시 buy했을때  24 hour시작
     */

    constructor() {
        phase[0] = block.timestamp + 24 hours;
        initialtime = block.timestamp;
    }

    struct UserInfo {
        address user;
        uint256 timelimit;
    }

    uint256 public initialtime;
    UserInfo[] public buyNum;
    mapping(uint256 => uint256) public phase;

    function nowPhase(uint256 blocktimestamp) public view returns (uint256) {
        return (blocktimestamp - initialtime) / 86400;
    }

    function buyPhaseChecker(
        uint256 blocktimestamp
    ) public view returns (bool) {
        return nowPhase(blocktimestamp) % 2 == 1;
    }

    function buy(uint256 _index) external payable {
        require(msg.value >= 0.1 ether && msg.value % (0.1 ether) == 0);

        console.log("phase[0]", phase[0]);

        // console.log("222", buyPhaseChecker(block.timestamp));
        console.log("noew", nowPhase(block.timestamp));

        if (block.timestamp > phase[0]) {
            phase[1] = phase[0] + 24 hours;
        }
        //
        buyNum.push();

        if (buyNum[_index].user != address(0)) {
            require(block.timestamp < buyNum[_index].timelimit);
            require(buyNum[_index].user != msg.sender);
        }
        buyNum[_index].user = msg.sender;
        buyNum[_index].timelimit = block.timestamp + 24 hours;
    }

    function draw() external {
        for (uint256 i; i < buyNum.length; i++) {
            require(block.timestamp < buyNum[i].timelimit);
        }
    }

    /**
    24시간동안 buy에 입력된 값들중에서 랜덤으로 뽑기. 
     */
    function winningNumber() external {}

    function claim() external {}

    receive() external payable {}
}
