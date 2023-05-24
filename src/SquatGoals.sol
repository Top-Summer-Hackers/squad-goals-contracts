// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ChallengeProxy.sol";
import "./ChallengeImplementation.sol";
import "./IChallenge.sol";
import "./RewardNFT.sol";

contract SquatGoals {
    error NotEnoughBalance();
    error TransferFailed();

    event ChallengeCreated(address challenge);

    address public treasury;
    address public challengeImplementation;
    mapping(uint256 => address) public challenges;
    mapping(address => address) public challengeNFT;
    uint256 public challengeCount = 1;

    constructor(address _treasury, address _challengeImplementation) {
        treasury = _treasury;
        challengeImplementation = _challengeImplementation;
    }

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
        challengeCount++;
        rewardNFT.transferOwnership(address(proxy));
        emit ChallengeCreated(address(proxy));
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
    ) external view returns (address, address) {
        return (
            challenges[_challengeId],
            challengeNFT[challenges[_challengeId]]
        );
    }

    receive() external payable {}
}
