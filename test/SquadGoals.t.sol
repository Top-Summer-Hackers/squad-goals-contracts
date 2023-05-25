pragma solidity ^0.8.19;
import "forge-std/Test.sol";
import "../src/SquadGoals.sol";
import "../src/ChallengeImplementation.sol";
import "../src/ChallengeProxy.sol";
import "../src/IChallenge.sol";

contract SquadGoalsTest is Test {
    SquadGoals squat;
    ChallengeImplementation challengeImplementation;
    RewardNFT rewardNFT;

    address account1 = vm.addr(1);
    address account2 = vm.addr(2);
    address account3 = vm.addr(3);
    address account4 = vm.addr(4);
    address treasury = vm.addr(4);

    function setUp() public {
        vm.deal(treasury, 1 ether);
        vm.deal(account1, 1 ether);
        vm.deal(account2, 1 ether);
        vm.deal(account3, 1 ether);

        challengeImplementation = new ChallengeImplementation();
        squat = new SquadGoals(treasury, address(challengeImplementation));
    }

    function createChallenge() public returns (address, address) {
        vm.prank(account1);
        squat.createChallenge(0.001 ether, 7, 30 days, "name", "symbol", "uri");
        (address challenge, address nft) = squat.getChallenge(1);
        require(
            ChallengeProxy(payable(challenge)).getImplementation() ==
                address(challengeImplementation)
        );
        return (challenge, nft);
    }

    function createChallengeMock(uint256 id) public returns (address, address) {
        vm.prank(account1);
        squat.createChallengeMock(id);
        (address challenge, address nft) = squat.getChallengeMock(1);
        require(
            ChallengeProxy(payable(challenge)).getImplementation() ==
                address(challengeImplementation)
        );
        return (challenge, nft);
    }

    function testImplementationAsProxy() public {
        (address challenge, address nftAddr) = createChallenge();
        rewardNFT = RewardNFT(nftAddr);
        challengeImplementation = ChallengeImplementation(challenge);
        uint256 timeNow = block.timestamp;
        vm.prank(account2);
        IChallenge(challenge).join{value: 0.001 ether}("account2");
        vm.prank(account3);
        IChallenge(challenge).join{value: 0.001 ether}("account3");
        vm.prank(account4);
        IChallenge(challenge).join{value: 0.001 ether}("account4");

        require(address(challengeImplementation).balance == 0.001 ether * 3);

        uint256 balanceBeforeCreator = account1.balance;
        uint256 balanceBeforeProtocol = address(squat).balance;
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
        uint256 balanceAfterCreator = account1.balance;
        uint256 balanceAfterProtocol = address(squat).balance;
        uint256 balanceAfterAccount2 = account2.balance;
        uint256 balanceAfterAccount3 = account3.balance;
        uint256 balanceAfterAccount4 = account4.balance;
        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 3
        );
        require(
            balanceAfterProtocol ==
                balanceBeforeProtocol + ((0.001 ether * 1000) / 10000) * 3
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
        balanceBeforeCreator = account1.balance;
        balanceBeforeProtocol = address(squat).balance;
        balanceBeforeAccount2 = account2.balance;
        balanceBeforeAccount3 = account3.balance;
        balanceBeforeAccount4 = account4.balance;
        vm.warp(timeNow + 35 days);
        challengeImplementation.executePayouts();
        balanceAfterCreator = account1.balance;
        balanceAfterProtocol = address(squat).balance;
        balanceAfterAccount2 = account2.balance;
        balanceAfterAccount3 = account3.balance;
        balanceAfterAccount4 = account4.balance;
        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 3
        );
        require(
            balanceAfterProtocol ==
                balanceBeforeProtocol + ((0.001 ether * 1000) / 10000) * 3
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

        uint256 balanceTreasuryBefore = treasury.balance;
        squat.withdraw();
        uint256 balanceTreasuryAfter = treasury.balance;
        require(
            balanceTreasuryAfter == balanceTreasuryBefore + balanceAfterProtocol
        );

        vm.expectRevert(abi.encodeWithSignature("NotEnoughBalance()"));
        squat.withdraw();
    }

    function testImplementationAsProxyForMock() public {
        (address challenge, address nftAddr) = createChallenge();
        (challenge, nftAddr) = createChallengeMock(1);

        rewardNFT = RewardNFT(nftAddr);
        challengeImplementation = ChallengeImplementation(challenge);

        uint256 timeNow = block.timestamp;
        vm.prank(account2);
        IChallenge(challenge).join{value: 0.001 ether}("account2");
        vm.prank(account3);
        IChallenge(challenge).join{value: 0.001 ether}("account3");
        vm.prank(account4);
        IChallenge(challenge).join{value: 0.001 ether}("account4");

        require(address(challengeImplementation).balance == 0.001 ether * 3);

        uint256 balanceBeforeCreator = account1.balance;
        uint256 balanceBeforeProtocol = address(squat).balance;
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
        uint256 balanceAfterCreator = account1.balance;
        uint256 balanceAfterProtocol = address(squat).balance;
        uint256 balanceAfterAccount2 = account2.balance;
        uint256 balanceAfterAccount3 = account3.balance;
        uint256 balanceAfterAccount4 = account4.balance;
        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 3
        );
        require(
            balanceAfterProtocol ==
                balanceBeforeProtocol + ((0.001 ether * 1000) / 10000) * 3
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
        balanceBeforeCreator = account1.balance;
        balanceBeforeProtocol = address(squat).balance;
        balanceBeforeAccount2 = account2.balance;
        balanceBeforeAccount3 = account3.balance;
        balanceBeforeAccount4 = account4.balance;
        vm.warp(timeNow + 35 days);
        challengeImplementation.executePayouts();
        balanceAfterCreator = account1.balance;
        balanceAfterProtocol = address(squat).balance;
        balanceAfterAccount2 = account2.balance;
        balanceAfterAccount3 = account3.balance;
        balanceAfterAccount4 = account4.balance;
        require(
            balanceAfterCreator ==
                balanceBeforeCreator + ((0.001 ether * 1000) / 10000) * 3
        );
        require(
            balanceAfterProtocol ==
                balanceBeforeProtocol + ((0.001 ether * 1000) / 10000) * 3
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

        uint256 balanceTreasuryBefore = treasury.balance;
        squat.withdraw();
        uint256 balanceTreasuryAfter = treasury.balance;
        require(
            balanceTreasuryAfter == balanceTreasuryBefore + balanceAfterProtocol
        );

        _checkForCorrectData();
    }

    function testCreateChallengeMock() public {
        (address challenge, address nftAddr) = createChallenge();

        vm.expectRevert(abi.encodeWithSignature("ChallengeDoesntExist()"));
        squat.createChallengeMock(2);

        (challenge, nftAddr) = createChallengeMock(1);

        rewardNFT = RewardNFT(nftAddr);
        challengeImplementation = ChallengeImplementation(challenge);

        require(challengeImplementation.stakeAmount() == 0.001 ether);
        require(challengeImplementation.maxAmountOfStakers() == 7);
        require(
            challengeImplementation.deadline() == block.timestamp + 30 days
        );
        require(challengeImplementation.stakerCount() == 0);
        require(challengeImplementation.votedCount() == 0);
        require(challengeImplementation.completed() == false);
        require(challengeImplementation.onVoting() == false);
    }

    function _checkForCorrectData() internal {
        SquadGoals.ChallengeReturnData[] memory data = squat.getAllChallenges();
        require(data.length == 2);
        require(data[1].challenge == address(challengeImplementation));
        require(data[1].NFT == address(rewardNFT));
        require(data[1].stakeAmount == 0.001 ether);
        require(data[1].maxAmountOfStakers == 7);
        require(data[1].stakerCount == 3);
        require(data[1].stakers.length == 3);
        require(data[1].votedCount == 2);
        require(data[1].completed == true);
        require(data[1].onVoting == false);
        require(data[1].stakers[0].stakerAddr == account2);
        require(data[1].stakers[0].stakerName == "account2");
        require(data[1].stakers[0].upVotes == 2);
        require(data[1].stakers[0].downVotes == 0);
        require(data[1].stakers[1].stakerAddr == account3);
        require(data[1].stakers[1].stakerName == "account3");
        require(data[1].stakers[1].upVotes == 0);
        require(data[1].stakers[1].downVotes == 1);
        require(data[1].stakers[2].stakerAddr == account4);
        require(data[1].stakers[2].stakerName == "account4");
        require(data[1].stakers[2].upVotes == 1);
        require(data[1].stakers[2].downVotes == 0);

        (address challenge1, address nftAddr1) = squat.getChallenge(1);

        require(data[0].challenge == challenge1);
        require(data[0].NFT == nftAddr1);
        require(data[0].stakeAmount == 0.001 ether);
        require(data[0].maxAmountOfStakers == 7);
        require(data[0].stakerCount == 0);
        require(data[0].stakers.length == 0);
        require(data[0].votedCount == 0);
        require(data[0].completed == false);
        require(data[0].onVoting == false);

        // USER CLAIMED NFTs

        SquadGoals.UserClaimedNFT[] memory claimedNFTs = squat
            .getUserClaimedNFTs(account2);

        require(claimedNFTs.length == 1);
        require(claimedNFTs[0].NFT == address(rewardNFT));
        require(claimedNFTs[0].tokenIds.length == 1);
        require(claimedNFTs[0].tokenIds[0] == 1);

        claimedNFTs = squat.getUserClaimedNFTs(account3);
        require(claimedNFTs.length == 0);

        claimedNFTs = squat.getUserClaimedNFTs(account4);
        require(claimedNFTs.length == 1);
        require(claimedNFTs[0].NFT == address(rewardNFT));
        require(claimedNFTs[0].tokenIds.length == 1);
        require(claimedNFTs[0].tokenIds[0] == 2);
    }
}
