// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Lottery.sol";
import "forge-std/console.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    uint256 received_msg_value;
    function setUp() public {
        lottery = new Lottery();
        received_msg_value = 0;
        vm.deal(address(this), 100 ether); // address(this)에 100eth
        vm.deal(address(1), 100 ether);
        vm.deal(address(2), 100 ether);
        vm.deal(address(3), 100 ether);
    }

    function testGoodBuy() public {
        lottery.buy{value: 0.1 ether}(0);
    }

    function testInsufficientFunds1() public {
        vm.expectRevert();
        lottery.buy(0);
    }

    function testInsufficientFunds2() public {
        vm.expectRevert();
        lottery.buy{value: 0.1 ether - 1}(0);
    }

    function testInsufficientFunds3() public {
        vm.expectRevert();
        lottery.buy{value: 0.1 ether + 1}(0);
    }

    function testNoDuplicate() public {
        // 같은 index 같은 사람=> revert
        lottery.buy{value: 0.1 ether}(0);
        vm.expectRevert();
        lottery.buy{value: 0.1 ether}(0);
    }

    function testSellPhaseFullLength() public {
        // 같은 index 24시간이내 다른 사람 ok
        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours - 1); // 24시간 -1초
        vm.prank(address(1));
        lottery.buy{value: 0.1 ether}(0);
    }

    function testNoBuyAfterPhaseEnd() public {
        // 같은 index 24시간 지나고 draw안했는데 다른사람 같은 index => revert
        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours); // 24시간
        vm.expectRevert();
        vm.prank(address(1));
        lottery.buy{value: 0.1 ether}(0);
    }

    function testNoDrawDuringSellPhase() public {
        // 24시간 안지났는데 draw => revert
        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours - 1);
        vm.expectRevert();
        lottery.draw();
    }

    function testNoClaimDuringSellPhase() public {
        // 24시간 안지났고 draw도 안했는데 claim => revert
        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours - 1);
        vm.expectRevert();
        lottery.claim();
    }

    function testDraw() public {
        // 24시간 지나고 draw => ok
        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
    }

    function getNextWinningNumber() private returns (uint16) {
        uint256 snapshotId = vm.snapshot();
        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
        uint16 winningNumber = lottery.winningNumber();
        vm.revertTo(snapshotId); // revertTo 스냅샷으로 롤백
        return winningNumber;
    }

    function testClaimOnWin() public {
        //24시간 지나고 draw하고 claim => ok
        uint16 winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber);
        vm.warp(block.timestamp + 24 hours);
        uint256 expectedPayout = address(lottery).balance;
        lottery.draw();
        lottery.claim();
        assertEq(received_msg_value, expectedPayout);
    }

    function testNoClaimOnLose() public {
        //winner아닌데 클레임 ? => 트랜잭션은 실행되는데 이더는 안보내줌
        uint16 winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber + 1);
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
        lottery.claim();
        assertEq(received_msg_value, 0);
    }

    function testNoDrawDuringClaimPhase() public {
        //24시간 지나고 draw하고 claim하고 바로 buy안햇는데 draw => revert
        uint16 winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber);
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
        lottery.claim();
        vm.expectRevert();
        lottery.draw();
    }

    function testRollover() public {
        //같은 사람 buy하고 24시간 지나고 draw하고 claim하고 다시 반복 => ok
        uint16 winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber + 1);
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
        lottery.claim(); // => 여기서 리워드를 안받아야함.

        winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber);
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
        lottery.claim();
        assertEq(received_msg_value, 0.2 ether);
    }

    function testSplit() public {
        //다른 사람이 같은 인덱스 buy하고 24시간 지나고 draw => 각각 클레임 가능
        uint16 winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber);
        vm.prank(address(1));
        lottery.buy{value: 0.1 ether}(winningNumber);
        vm.deal(address(1), 0);

        vm.warp(block.timestamp + 24 hours);
        lottery.draw();

        lottery.claim();
        assertEq(received_msg_value, 0.1 ether);

        vm.prank(address(1));
        lottery.claim();
        assertEq(address(1).balance, 0.1 ether);
    }

    receive() external payable {
        received_msg_value = msg.value;
    }
}
