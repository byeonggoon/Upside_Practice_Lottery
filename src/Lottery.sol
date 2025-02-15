// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
contract Lottery {
    /**
    Lottery
    
    buy처음하면 24 hour시작. 
    
    같은 index 24시간이내 같은 사람 => revert
    같은 index 24시간이내 다른 사람 => ok
    같은 index 24시간 지나고 draw안했는데 다른사람 같은 index => revert
    24시간 안지났는데 draw => revert
    24시간 안지났고 draw도 안했는데 claim => revert
    24시간 지나고 draw => ok
    winner아닌데 클레임 ? => 트랜잭션은 실행되는데 이더는 안보내줌     
    24시간 지나고 draw하고 claim => ok
    24시간 지나고 draw하고 claim하고 바로 buy안햇는데 draw => revert
    같은 사람 buy하고 24시간 지나고 draw하고 claim하고 다시 반복 => ok
    다른 사람이 같은 인덱스 buy하고 24시간 지나고 draw => 각각 클레임 가능 
     */

    constructor() {
        phaseTimeLimit = block.timestamp + 24 hours;
        owner = msg.sender;
    }

    uint256 public phaseTimeLimit;
    uint256 public luckyVikcyNum;
    bool public buyPhase;
    bool public drawPhase;
    bool public claimPhase;
    mapping(uint256 => address[]) public buyUserlist;
    uint256[] public usedBettingNums;
    uint256 public totalRewards;
    uint256 public rewardPerWinner;
    address public owner;

    function buy(uint256 _bettingNum) external payable {
        require(msg.value == 0.1 ether);

        if (
            (buyPhase == false && drawPhase == false && claimPhase == true) ||
            ((buyPhase == true && drawPhase == true && claimPhase == false) &&
                block.timestamp >= phaseTimeLimit)
        ) {
            phaseTimeLimit = block.timestamp + 24 hours;
        }

        require(block.timestamp < phaseTimeLimit, "END PHASE WAIT NEXT PHASE");

        if (
            buyUserlist[_bettingNum].length > 0 &&
            buyUserlist[_bettingNum][0] != address(0)
        ) {
            for (uint256 i = 0; i < buyUserlist[_bettingNum].length; i++) {
                require(
                    buyUserlist[_bettingNum][i] != msg.sender,
                    "NOT MATCHED"
                );
            }
        }

        buyUserlist[_bettingNum].push(msg.sender);
        usedBettingNums.push(_bettingNum);

        buyPhase = true;
        drawPhase = false;
        claimPhase = false;
    }

    function draw() external {
        require(block.timestamp >= phaseTimeLimit);
        require(buyPhase, "not yes buyPhase");
        require(owner == msg.sender);
        luckyVikcyNum = winningNumber();

        buyPhase = true;
        drawPhase = true;
        claimPhase = false;
        totalRewards = address(this).balance;
    }

    function winningNumber() public returns (uint16) {
        /** 
         지금은 테스트를 위해 무작위 값이 아닌 고정된 값을 리턴. 
        */
        return 0;
    }

    function claim() external {
        require(block.timestamp >= phaseTimeLimit);
        require(buyPhase && drawPhase, "not yet claimPhase");

        address[] storage winners = buyUserlist[luckyVikcyNum];

        if (winners.length == 0) {
            return;
        }

        uint256 rewardUserCount = winners.length;
        uint256 eachReward = totalRewards / rewardUserCount;

        for (uint256 i; i < rewardUserCount; i++) {
            if ((winners[i] == msg.sender)) {
                winners[i] = winners[winners.length - 1];
                winners.pop();
                break;
            }
        }

        if (winners.length == 0) {
            buyPhase = false;
            drawPhase = false;
            claimPhase = true;
            clearBuyUserlist();
        }
        totalRewards -= eachReward;
        (bool success, ) = payable(msg.sender).call{value: eachReward}("");
        require(success);
    }

    function clearBuyUserlist() public {
        for (uint256 i = 0; i < usedBettingNums.length; i++) {
            uint256 num = usedBettingNums[i];
            delete buyUserlist[num];
        }
        delete usedBettingNums;
    }

    receive() external payable {}
}
