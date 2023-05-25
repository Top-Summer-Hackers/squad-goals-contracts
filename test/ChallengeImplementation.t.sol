pragma solidity ^0.8.19;
import "forge-std/Test.sol";
import "../src/ChallengeImplementation.sol";
import "../src/RewardNFT.sol";

contract ChallengeImplementationTest is Test {
    ChallengeImplementation challengeImplementation;
    RewardNFT rewardNFT;
    address creator = vm.addr(1);
    address account2 = vm.addr(2);
    address account3 = vm.addr(3);
    address account4 = vm.addr(4);
    address account5 = vm.addr(5);
    address account6 = vm.addr(6);
    address account7 = vm.addr(7);
    address account8 = vm.addr(8);
    address account9 = vm.addr(9);

    uint256 constant stakeAmount = 0.001 ether;
    uint256 constant maxAmountOfStakers = 7;
    uint256 constant duration = 30 days;

    function setUp() public {
        vm.deal(creator, 100 ether);
        vm.deal(account2, 100 ether);
        vm.deal(account3, 100 ether);
        vm.deal(account4, 100 ether);
        vm.deal(account5, 100 ether);
        vm.deal(account6, 100 ether);
        vm.deal(account7, 100 ether);
        vm.deal(account8, 100 ether);
        vm.deal(account9, 100 ether);

        rewardNFT = new RewardNFT("BALIREWARD", "BALI", "ipfs://siuuu1");
        challengeImplementation = new ChallengeImplementation();
        challengeImplementation.initialize(
            stakeAmount,
            maxAmountOfStakers,
            duration,
            address(rewardNFT),
            creator
        );
        rewardNFT.setAuthorizedMinter(address(challengeImplementation));
    }

    function testCannotInitializeAgain() public {
        vm.expectRevert(
            abi.encodeWithSignature("ContractAlreadyInitialized()")
        );
        challengeImplementation.initialize(
            stakeAmount,
            maxAmountOfStakers,
            duration,
            address(rewardNFT),
            creator
        );
    }

    function testJoinRequireCorrectAmountOfEther() public {
        vm.startPrank(account2);

        // Should fail because the amount of ether sent is not equal to the stake amount
        vm.expectRevert(abi.encodeWithSignature("IncorrectAmountOfEthSent()"));
        challengeImplementation.join{value: 0.0001 ether}("account2");
        // should work because the amount of ether sent is equal to the stake amount
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.stopPrank();
    }

    function testJoinRequireWithinDeadline() public {
        uint256 timeNow = block.timestamp;
        vm.startPrank(account2);
        vm.warp(timeNow + 31 days);
        vm.expectRevert(
            abi.encodeWithSignature("DeadlineHasPassed(bool)", true)
        );
        challengeImplementation.join{value: 0.001 ether}("account2");

        vm.warp(timeNow + 15 days);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.stopPrank();
    }

    function testJoinRequireCorrectAmountOfTotalStakers() public {
        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");
        vm.prank(account4);
        challengeImplementation.join{value: 0.001 ether}("account4");
        vm.prank(account5);
        challengeImplementation.join{value: 0.001 ether}("account5");
        vm.prank(account6);
        challengeImplementation.join{value: 0.001 ether}("account6");
        vm.prank(account7);
        challengeImplementation.join{value: 0.001 ether}("account7");
        vm.prank(account8);
        challengeImplementation.join{value: 0.001 ether}("account8");

        vm.prank(account9);
        vm.expectRevert(abi.encodeWithSignature("MaxAmountOfStakersReached()"));
        challengeImplementation.join{value: 0.001 ether}("account9");
    }

    function testJoinCantDoTwiceSameAddress() public {
        vm.startPrank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.expectRevert(abi.encodeWithSignature("HasJoined(bool)", true));
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.stopPrank();
    }

    function testJoinRecordsCorrectData() public {
        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");
        vm.prank(account4);
        challengeImplementation.join{value: 0.001 ether}("account4");

        require(challengeImplementation.stakerCount() == 3);
        require(
            challengeImplementation.getStaker(account2).stakerAddr == account2
        );

        require(
            challengeImplementation.getStaker(account3).stakerAddr == account3
        );

        require(
            challengeImplementation.getStaker(account4).stakerAddr == account4
        );

        ChallengeImplementation.Staker[]
            memory stakers = challengeImplementation.getStakers();

        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i].stakerAddr == account2) {
                require(stakers[i].stakerName == "account2");
            }
            if (stakers[i].stakerAddr == account3) {
                require(stakers[i].stakerName == "account3");
            }
            if (stakers[i].stakerAddr == account4) {
                require(stakers[i].stakerName == "account4");
            }
            require(stakers[i].upVotes == 0);
            require(stakers[i].downVotes == 0);
        }
    }

    function testSubmitVote1ParticipantShouldFail() public {
        vm.startPrank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.expectRevert(abi.encodeWithSignature("NotEnoughStakers()"));
        ChallengeImplementation.Vote[]
            memory votes = new ChallengeImplementation.Vote[](1);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        challengeImplementation.submitVote(votes);
        vm.stopPrank();
    }

    function testSubmitVoteRequiresDeadlinePassedAndCooldownOnAndCorrectAmountOfVotes()
        public
    {
        uint256 timeNow = block.timestamp;
        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");

        vm.expectRevert(abi.encodeWithSignature("NoInCoolDownPeriod()"));
        ChallengeImplementation.Vote[]
            memory votes = new ChallengeImplementation.Vote[](1);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        vm.prank(account3);
        challengeImplementation.submitVote(votes);

        vm.warp(timeNow + 34 days);
        vm.expectRevert(abi.encodeWithSignature("NoInCoolDownPeriod()"));
        vm.prank(account3);
        challengeImplementation.submitVote(votes);

        vm.warp(timeNow + 31 days);

        votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        votes[1] = ChallengeImplementation.Vote(account3, true);
        vm.expectRevert(abi.encodeWithSignature("IncorrectAmountOfVotes()"));
        vm.prank(account3);
        challengeImplementation.submitVote(votes);

        votes = new ChallengeImplementation.Vote[](1);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        vm.prank(account3);
        challengeImplementation.submitVote(votes);
    }

    function testSubmitVotesCorrectlyUpdatesStates() public {
        uint256 timeNow = block.timestamp;

        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");

        vm.warp(timeNow + 31 days);

        ChallengeImplementation.Vote[]
            memory votes = new ChallengeImplementation.Vote[](1);
        votes[0] = ChallengeImplementation.Vote(account2, true);

        vm.prank(account3);
        challengeImplementation.submitVote(votes);

        require(!challengeImplementation.hasVoted(account2));
        require(challengeImplementation.hasVoted(account3));
        require(!challengeImplementation.hasVotedFor(account3, account3));
        require(challengeImplementation.hasVotedFor(account3, account2));

        votes = new ChallengeImplementation.Vote[](1);
        votes[0] = ChallengeImplementation.Vote(account3, false);
        vm.prank(account2);
        challengeImplementation.submitVote(votes);

        require(challengeImplementation.hasVoted(account2));
        require(challengeImplementation.hasVoted(account3));
        require(challengeImplementation.hasVotedFor(account3, account2));
        require(challengeImplementation.hasVotedFor(account2, account3));

        ChallengeImplementation.Staker memory staker2 = challengeImplementation
            .getStaker(account2);

        ChallengeImplementation.Staker memory staker3 = challengeImplementation
            .getStaker(account3);

        require(staker2.upVotes == 1);
        require(staker2.downVotes == 0);
        require(staker3.upVotes == 0);
        require(staker3.downVotes == 1);

        require(challengeImplementation.votedCount() == 2);
        require(challengeImplementation.stakerCount() == 2);
    }

    function testCoreChecksOnVoting() public {
        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");
        vm.prank(account4);
        challengeImplementation.join{value: 0.001 ether}("account4");

        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(abi.encodeWithSignature("HasJoined(bool)", false));
        ChallengeImplementation.Vote[]
            memory votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account3, true);
        votes[1] = ChallengeImplementation.Vote(account4, true);
        vm.prank(account5);
        challengeImplementation.submitVote(votes);

        votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account3, true);
        votes[1] = ChallengeImplementation.Vote(account3, true);

        vm.expectRevert(abi.encodeWithSignature("AlreadyVoted()"));
        vm.prank(account2);
        challengeImplementation.submitVote(votes);

        votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account3, true);
        votes[1] = ChallengeImplementation.Vote(account5, true);

        vm.expectRevert(abi.encodeWithSignature("HasJoined(bool)", false));
        vm.prank(account2);
        challengeImplementation.submitVote(votes);

        uint256 sp = vm.snapshot();

        votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account3, true);
        votes[1] = ChallengeImplementation.Vote(account4, true);
        vm.prank(account2);
        challengeImplementation.submitVote(votes);

        vm.expectRevert(abi.encodeWithSignature("AlreadyVoted()"));
        vm.prank(account2);
        challengeImplementation.submitVote(votes);

        vm.revertTo(sp);
    }

    function test1Staker() public {
        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        uint256 balanceBefore = account2.balance;

        vm.warp(block.timestamp + 35 days);
        challengeImplementation.executePayouts();

        uint256 balanceAfter = account2.balance;

        require(balanceAfter == balanceBefore + 0.001 ether);
        require(address(challengeImplementation).balance == 0);
    }

    function testExecutePayoutAllSucceeded() external {
        uint256 snp = vm.snapshot();

        uint256 timeNow = block.timestamp;

        vm.warp(timeNow + 35 days);
        vm.expectRevert(abi.encodeWithSignature("NotEnoughStakers()"));
        challengeImplementation.executePayouts();

        vm.warp(timeNow);

        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");
        vm.prank(account4);
        challengeImplementation.join{value: 0.001 ether}("account4");
        vm.prank(account5);
        challengeImplementation.join{value: 0.001 ether}("account5");

        vm.warp(timeNow + 31 days);

        ChallengeImplementation.Vote[]
            memory votes = new ChallengeImplementation.Vote[](3);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        votes[1] = ChallengeImplementation.Vote(account3, true);
        votes[2] = ChallengeImplementation.Vote(account4, true);
        vm.prank(account5);
        challengeImplementation.submitVote(votes);

        votes = new ChallengeImplementation.Vote[](3);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        votes[1] = ChallengeImplementation.Vote(account3, true);
        votes[2] = ChallengeImplementation.Vote(account5, true);
        vm.prank(account4);
        challengeImplementation.submitVote(votes);

        votes = new ChallengeImplementation.Vote[](3);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        votes[1] = ChallengeImplementation.Vote(account4, true);
        votes[2] = ChallengeImplementation.Vote(account5, true);
        vm.prank(account3);
        challengeImplementation.submitVote(votes);

        votes = new ChallengeImplementation.Vote[](3);
        votes[0] = ChallengeImplementation.Vote(account3, true);
        votes[1] = ChallengeImplementation.Vote(account4, true);
        votes[2] = ChallengeImplementation.Vote(account5, true);
        vm.prank(account2);
        challengeImplementation.submitVote(votes);

        vm.expectRevert(
            abi.encodeWithSignature("DeadlineHasPassed(bool)", false)
        );
        challengeImplementation.executePayouts();

        vm.warp(timeNow + 35 days);

        uint256 balanceBeforeCreator = creator.balance;
        uint256 balanceBeforeThis = address(this).balance;

        challengeImplementation.executePayouts();

        uint256 balanceAfterCreator = creator.balance;
        uint256 balanceAfterThis = address(this).balance;

        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 4
        );

        require(
            balanceAfterThis ==
                balanceBeforeThis + ((0.001 ether * 1000) / 10000) * 4
        );

        vm.revertTo(snp);
    }

    function testExecutePayout1Outof2NotSucceded() public {
        uint256 timeNow = block.timestamp;
        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");

        uint256 snp = vm.snapshot();

        vm.warp(timeNow + 35 days);
        uint256 balanceBeforeCreator = creator.balance;
        uint256 balanceBeforeThis = address(this).balance;
        uint256 balanceBeforeAccount2 = account2.balance;
        uint256 balanceBeforeAccount3 = account3.balance;

        challengeImplementation.executePayouts();

        uint256 balanceAfterCreator = creator.balance;
        uint256 balanceAfterThis = address(this).balance;
        uint256 balanceAfterAccount2 = account2.balance;
        uint256 balanceAfterAccount3 = account3.balance;

        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 2
        );
        require(
            balanceAfterThis ==
                balanceBeforeThis + ((0.001 ether * 1000) / 10000) * 2
        );
        require(
            balanceAfterAccount2 ==
                balanceBeforeAccount2 + ((0.001 ether * 8000) / 10000)
        );
        require(
            balanceAfterAccount3 ==
                balanceBeforeAccount3 + ((0.001 ether * 8000) / 10000)
        );

        vm.revertTo(snp);

        vm.warp(timeNow + 31 days);
        ChallengeImplementation.Vote[]
            memory votes = new ChallengeImplementation.Vote[](1);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        vm.prank(account3);
        challengeImplementation.submitVote(votes);

        balanceBeforeCreator = creator.balance;
        balanceBeforeThis = address(this).balance;
        balanceBeforeAccount2 = account2.balance;
        balanceBeforeAccount3 = account3.balance;

        vm.warp(timeNow + 35 days);

        challengeImplementation.executePayouts();

        balanceAfterCreator = creator.balance;
        balanceAfterThis = address(this).balance;
        balanceAfterAccount2 = account2.balance;
        balanceAfterAccount3 = account3.balance;

        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 2
        );
        require(
            balanceAfterThis ==
                balanceBeforeThis + ((0.001 ether * 1000) / 10000) * 2
        );
        require(
            balanceAfterAccount2 ==
                balanceBeforeAccount2 + ((0.001 ether * 8000) / 10000) * 2
        );
        require(balanceAfterAccount3 == balanceBeforeAccount3);
    }

    function testExecutePayout1And2Outof3NotSucceded() public {
        uint256 timeNow = block.timestamp;
        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");
        vm.prank(account4);
        challengeImplementation.join{value: 0.001 ether}("account4");

        uint256 balanceBeforeCreator = creator.balance;
        uint256 balanceBeforeThis = address(this).balance;
        uint256 balanceBeforeAccount2 = account2.balance;
        uint256 balanceBeforeAccount3 = account3.balance;
        uint256 balanceBeforeAccount4 = account4.balance;

        vm.warp(timeNow + 31 days);

        ChallengeImplementation.Vote[]
            memory votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        votes[1] = ChallengeImplementation.Vote(account3, false);
        vm.prank(account4);
        challengeImplementation.submitVote(votes);

        uint256 snp = vm.snapshot();

        vm.warp(timeNow + 35 days);

        challengeImplementation.executePayouts();

        uint256 balanceAfterCreator = creator.balance;
        uint256 balanceAfterThis = address(this).balance;
        uint256 balanceAfterAccount2 = account2.balance;
        uint256 balanceAfterAccount3 = account3.balance;
        uint256 balanceAfterAccount4 = account4.balance;

        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 3
        );
        require(
            balanceAfterThis ==
                balanceBeforeThis + ((0.001 ether * 1000) / 10000) * 3
        );
        require(
            balanceAfterAccount2 ==
                balanceBeforeAccount2 + ((0.001 ether * 8000) / 10000)
        );
        require(
            balanceAfterAccount3 ==
                balanceBeforeAccount3 + ((0.001 ether * 8000) / 10000)
        );
        require(
            balanceAfterAccount4 ==
                balanceBeforeAccount4 + ((0.001 ether * 8000) / 10000)
        );

        vm.revertTo(snp);
        votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account2, true);
        votes[1] = ChallengeImplementation.Vote(account4, true);
        vm.prank(account3);
        challengeImplementation.submitVote(votes);

        balanceBeforeCreator = creator.balance;
        balanceBeforeThis = address(this).balance;
        balanceBeforeAccount2 = account2.balance;
        balanceBeforeAccount3 = account3.balance;
        balanceBeforeAccount4 = account4.balance;

        vm.warp(timeNow + 35 days);

        challengeImplementation.executePayouts();

        balanceAfterCreator = creator.balance;
        balanceAfterThis = address(this).balance;
        balanceAfterAccount2 = account2.balance;
        balanceAfterAccount3 = account3.balance;
        balanceAfterAccount4 = account4.balance;

        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 3
        );
        require(
            balanceAfterThis ==
                balanceBeforeThis + ((0.001 ether * 1000) / 10000) * 3
        );
        require(
            balanceAfterAccount2 ==
                balanceBeforeAccount2 +
                    ((0.001 ether * 8000) / 10000) +
                    ((0.001 ether * 4000) / 10000)
        );
        require(
            balanceAfterAccount4 ==
                balanceBeforeAccount4 +
                    ((0.001 ether * 8000) / 10000) +
                    ((0.001 ether * 4000) / 10000)
        );
        require(balanceAfterAccount3 == balanceBeforeAccount3);

        require(rewardNFT.balanceOf(account3) == 0);
        require(rewardNFT.balanceOf(account4) == 1);
        require(rewardNFT.balanceOf(account2) == 1);
    }

    function testAllUsersDontPass() public {
        uint256 timeNow = block.timestamp;
        vm.prank(account2);
        challengeImplementation.join{value: 0.001 ether}("account2");
        vm.prank(account3);
        challengeImplementation.join{value: 0.001 ether}("account3");
        vm.prank(account4);
        challengeImplementation.join{value: 0.001 ether}("account4");

        vm.warp(timeNow + 31 days);

        ChallengeImplementation.Vote[]
            memory votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account2, false);
        votes[1] = ChallengeImplementation.Vote(account3, false);

        vm.prank(account4);
        challengeImplementation.submitVote(votes);

        votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account3, false);
        votes[1] = ChallengeImplementation.Vote(account4, false);

        vm.prank(account2);
        challengeImplementation.submitVote(votes);

        votes = new ChallengeImplementation.Vote[](2);
        votes[0] = ChallengeImplementation.Vote(account2, false);
        votes[1] = ChallengeImplementation.Vote(account4, false);

        vm.prank(account3);
        challengeImplementation.submitVote(votes);

        vm.warp(timeNow + 35 days);

        uint256 balanceBeforeCreator = creator.balance;
        uint256 balanceBeforeThis = address(this).balance;
        uint256 balanceBeforeAccount2 = account2.balance;
        uint256 balanceBeforeAccount3 = account3.balance;
        uint256 balanceBeforeAccount4 = account4.balance;

        challengeImplementation.executePayouts();

        uint256 balanceAfterCreator = creator.balance;
        uint256 balanceAfterThis = address(this).balance;
        uint256 balanceAfterAccount2 = account2.balance;
        uint256 balanceAfterAccount3 = account3.balance;
        uint256 balanceAfterAccount4 = account4.balance;

        require(balanceAfterAccount2 == balanceBeforeAccount2);
        require(balanceAfterAccount3 == balanceBeforeAccount3);
        require(balanceAfterAccount4 == balanceBeforeAccount4);

        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 3
        );

        require(
            balanceAfterThis ==
                balanceBeforeThis +
                    ((0.001 ether * 1000) / 10000) *
                    3 +
                    ((0.001 ether * 8000) / 10000) *
                    3
        );
    }

    receive() external payable {}
}
