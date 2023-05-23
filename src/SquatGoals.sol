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

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function createChallenge(
        uint256 _stakeAmount,
        uint256 _maxAmountOfStakers,
        uint256 _duration,
        string memory _name,
        string memory _symbol
    ) external {
        RewardNFT rewardNFT = new RewardNFT(_name, _symbol, "ipfs://");
        ChallengeProxy proxy = new ChallengeProxy(challengeImplementation);
        IChallenge(address(proxy)).initialize(
            _stakeAmount,
            _maxAmountOfStakers,
            _duration,
            address(rewardNFT),
            msg.sender
        );
        rewardNFT.transferOwnership(address(treasury));
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

    receive() external payable {}
}
