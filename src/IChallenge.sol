pragma solidity ^0.8.19;

interface IChallenge {
    struct Staker {
        address stakerAddr;
        bytes32 stakerName;
        uint256 upVotes;
        uint256 downVotes;
    }

    function initialize(
        uint256 _stakeAmount,
        uint256 _maxAmountOfStakers,
        uint256 _duration,
        address _rewardNFTAddr,
        address _creator
    ) external;

    function join(bytes32 _name) external payable;

    function completed() external view returns (bool);

    function stakeAmount() external view returns (uint256);

    function maxAmountOfStakers() external view returns (uint256);

    function deadline() external view returns (uint256);

    function stakerCount() external view returns (uint256);

    function votedCount() external view returns (uint256);

    function getStakers() external view returns (Staker[] memory);

    function onVoting() external view returns (bool);
}
