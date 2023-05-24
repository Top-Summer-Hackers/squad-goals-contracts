pragma solidity ^0.8.19;
import "forge-std/Test.sol";
import "../src/SquatGoals.sol";
import "../src/ChallengeImplementation.sol";
import "../src/ChallengeProxy.sol";
import "../src/IChallenge.sol";

contract SquatGoalsTest is Test {
    SquatGoals squat;
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
        squat = new SquatGoals(treasury, address(challengeImplementation));
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
    }
}
