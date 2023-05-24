pragma solidity ^0.8.19;

interface IChallenge {
    function initialize(
        uint256 _stakeAmount,
        uint256 _maxAmountOfStakers,
        uint256 _duration,
        address _rewardNFTAddr,
        address _creator
    ) external;

    function join(bytes32 _name) external payable;
}
