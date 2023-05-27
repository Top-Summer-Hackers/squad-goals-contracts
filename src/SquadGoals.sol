// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ChallengeProxy.sol";
import "./ChallengeImplementation.sol";
import "./IChallenge.sol";
import "./RewardNFT.sol";

/**
 * @title SquadGoals
 * @author Carlos Ramos
 */
contract SquadGoals {
    error NotEnoughBalance();
    error TransferFailed();
    error ChallengeDoesntExist();

    event ChallengeCreated(address challenge);

    struct UserClaimedNFT {
        address NFT;
        uint256[] tokenIds;
    }

    struct ChallengeReturnData {
        address challenge;
        address NFT;
        uint256 stakeAmount;
        uint256 maxAmountOfStakers;
        uint256 deadline;
        uint256 stakerCount;
        ChallengeImplementation.Staker[] stakers;
        uint256 votedCount;
        bool completed;
        bool onVoting;
    }

    address public treasury;
    address public challengeImplementation;
    mapping(uint256 => address) public challenges;
    mapping(uint256 => bytes) public challengeInitData;
    mapping(address => address) public challengeNFT;

    mapping(uint256 => address) public challengeCopys;
    mapping(address => address) public challengeCopyNFT;
    mapping(uint256 => address[]) public copiesOfChallengeId;

    uint256 public challengeCount = 1;
    uint256 public copyCount = 1;

    constructor(address _treasury, address _challengeImplementation) {
        treasury = _treasury;
        challengeImplementation = _challengeImplementation;
    }

    /**
     *
     * @param _stakeAmount The amount of ETH to stake
     * @param _maxAmountOfStakers The maximum amount of stakers
     * @param _duration The duration of the Challenge
     * @param _name The name of the RewardNFT
     * @param _symbol The symbol of the RewardNFT
     * @param _uri The uri of the RewardNFT
     * @dev This function deploys a new proxy and assigns the basic implementation of Challenge
     * @dev this function will deploy a new RewardNFT and assign it to the Challenge
     */
    function createChallenge(
        uint256 _stakeAmount,
        uint256 _maxAmountOfStakers,
        uint256 _duration,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external {
        RewardNFT rewardNFT = new RewardNFT(_name, _symbol, _uri);
        ChallengeProxy proxy = new ChallengeProxy(challengeImplementation);
        IChallenge(address(proxy)).initialize(
            _stakeAmount,
            _maxAmountOfStakers,
            _duration,
            address(rewardNFT),
            msg.sender
        );
        challenges[challengeCount] = address(proxy);
        challengeNFT[address(proxy)] = address(rewardNFT);
        challengeInitData[challengeCount] = abi.encode(
            _stakeAmount,
            _maxAmountOfStakers,
            _duration,
            address(rewardNFT),
            msg.sender
        );
        challengeCount++;
        rewardNFT.setAuthorizedMinter(address(proxy));
        emit ChallengeCreated(address(proxy));
    }

    /**
     *
     * @param _challengeId the id of the challenge to copy
     */
    function createChallengeCopy(uint256 _challengeId) external {
        bytes memory initData = challengeInitData[_challengeId];

        if (challenges[_challengeId] == address(0)) {
            revert ChallengeDoesntExist();
        }

        (
            uint256 _stakeAmount,
            uint256 _maxAmountOfStakers,
            uint256 _duration,
            address _rewardNFT,
            address _creator
        ) = abi.decode(initData, (uint256, uint256, uint256, address, address));
        ChallengeProxy proxy = new ChallengeProxy(challengeImplementation);
        IChallenge(address(proxy)).initialize(
            _stakeAmount,
            _maxAmountOfStakers,
            _duration,
            _rewardNFT,
            _creator
        );
        challengeCopyNFT[address(proxy)] = _rewardNFT;
        RewardNFT(_rewardNFT).setAuthorizedMinter(address(proxy));
        challengeCopys[copyCount] = address(proxy);
        copiesOfChallengeId[_challengeId].push(address(proxy));
        copyCount++;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = treasury.call{value: balance}("");
            if (!success) revert TransferFailed();
        } else {
            revert NotEnoughBalance();
        }
    }

    function getChallenge(
        uint256 _challengeId
    ) public view returns (address, address) {
        return (
            challenges[_challengeId],
            challengeNFT[challenges[_challengeId]]
        );
    }

    function getChallengeCopy(
        uint256 _challengeId
    ) public view returns (address, address) {
        return (
            challengeCopys[_challengeId],
            challengeCopyNFT[challengeCopys[_challengeId]]
        );
    }

    function getUserClaimedNFTs(
        address _user
    ) external view returns (UserClaimedNFT[] memory claimedNFTs) {
        // get the count of challenges the user has claimed
        uint256 claimedCount;
        for (uint256 i = 1; i < challengeCount; i++) {
            if (RewardNFT(challengeNFT[challenges[i]]).balanceOf(_user) > 0) {
                claimedCount++;
            }
        }

        // create the array of UserClaimedNFTs
        claimedNFTs = new UserClaimedNFT[](claimedCount);
        uint256 j;
        for (uint256 i = 1; i < challengeCount; i++) {
            uint256 userBalance = RewardNFT(challengeNFT[challenges[i]])
                .balanceOf(_user);
            if (userBalance > 0) {
                uint256[] memory ids = new uint256[](userBalance);
                for (uint256 j = 0; j < userBalance; j++) {
                    ids[j] = RewardNFT(challengeNFT[challenges[i]])
                        .tokenOfOwnerByIndex(_user, j);
                }
                claimedNFTs[j] = UserClaimedNFT(
                    challengeNFT[challenges[i]],
                    ids
                );
                j++;
            }
        }
    }

    function getChallenges()
        public
        view
        returns (ChallengeReturnData[] memory openChallenges)
    {
        openChallenges = new ChallengeReturnData[](challengeCount - 1);

        for (uint256 i = 1; i < challengeCount; i++) {
            address challenge = challenges[i];
            openChallenges[i - 1] = ChallengeReturnData(
                challenge,
                challengeNFT[challenge],
                IChallenge(challenge).stakeAmount(),
                IChallenge(challenge).maxAmountOfStakers(),
                IChallenge(challenge).deadline(),
                IChallenge(challenge).stakerCount(),
                IChallenge(challenge).getStakers(),
                IChallenge(challenge).votedCount(),
                IChallenge(challenge).completed(),
                IChallenge(challenge).onVoting()
            );
        }
    }

    function getChallengeCopies()
        public
        view
        returns (ChallengeReturnData[] memory openChallenges)
    {
        openChallenges = new ChallengeReturnData[](copyCount - 1);

        for (uint256 i = 1; i < copyCount; i++) {
            address challenge = challengeCopys[i];
            openChallenges[i - 1] = ChallengeReturnData(
                challenge,
                challengeCopyNFT[challenge],
                IChallenge(challenge).stakeAmount(),
                IChallenge(challenge).maxAmountOfStakers(),
                IChallenge(challenge).deadline(),
                IChallenge(challenge).stakerCount(),
                IChallenge(challenge).getStakers(),
                IChallenge(challenge).votedCount(),
                IChallenge(challenge).completed(),
                IChallenge(challenge).onVoting()
            );
        }
    }

    function getCopiesOfChallenge(
        uint256 _challengeId
    ) external view returns (address[] memory) {
        return copiesOfChallengeId[_challengeId];
    }

    function getAllChallenges()
        external
        view
        returns (
            ChallengeReturnData[] memory openChallenges,
            ChallengeReturnData[] memory openChallengeCopies
        )
    {
        return (getChallenges(), getChallengeCopies());
    }

    receive() external payable {}
}
