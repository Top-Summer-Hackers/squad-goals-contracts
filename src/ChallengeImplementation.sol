pragma solidity 0.8.19;
import "./IRewardNFT.sol";
import "forge-std/console.sol";

contract ChallengeImplementation {
    error ContractAlreadyInitialized();
    error MaxAmountOfStakersReached();
    error IncorrectAmountOfEthSent();
    error DeadlineHasPassed(bool);
    error HasJoined(bool);
    error NoInCoolDownPeriod();
    error IncorrectAmountOfVotes();
    error AlreadyVoted();
    error InvalidVote();
    error TransferFailed();
    error NotEnoughStakers();

    struct Staker {
        address stakerAddr;
        bytes32 stakerName;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct Vote {
        address stakerAddr;
        bool isUpvote;
    }

    uint256 constant CREATOR_FEE = 1000;
    uint256 constant PROTOCOL_FEE = 1000;
    uint256 constant STAKER_FEE = 8000;
    uint256 constant COOLDOWN_PERIOD = 3 days;

    address creator;
    address SquadGoalsAddr;
    address rewardNFTAddr;
    uint256 public stakeAmount;
    uint256 maxAmountOfStakers;
    uint256 deadline;
    uint256 public stakerCount = 0;
    uint256 public votedCount;

    mapping(address => Staker) stakers;
    mapping(uint256 => address) stakerIds;
    mapping(address => bool) public hasVoted;
    mapping(address => mapping(address => bool)) public hasVotedFor;
    bool private initialized;

    function initialize(
        uint256 _stakeAmount,
        uint256 _maxAmountOfStakers,
        uint256 _duration,
        address _rewardNFTAddr,
        address _creator
    ) public {
        if (initialized) revert ContractAlreadyInitialized();
        initialized = true;
        rewardNFTAddr = _rewardNFTAddr;
        deadline = block.timestamp + _duration;
        stakeAmount = _stakeAmount;
        maxAmountOfStakers = _maxAmountOfStakers;
        SquadGoalsAddr = msg.sender;
        creator = _creator;
    }

    function join(bytes32 _name) external payable {
        if (block.timestamp > deadline) revert DeadlineHasPassed(true);
        if (stakerCount == maxAmountOfStakers)
            revert MaxAmountOfStakersReached();
        if (msg.value != stakeAmount) revert IncorrectAmountOfEthSent();
        if (stakers[msg.sender].stakerAddr != address(0))
            revert HasJoined(true);

        stakers[msg.sender] = Staker(msg.sender, _name, 0, 0);
        stakerIds[stakerCount] = msg.sender;
        stakerCount++;
    }

    function submitVote(Vote[] calldata _votes) external {
        if (stakers[msg.sender].stakerAddr == address(0)) {
            revert HasJoined(false);
        }
        if (stakerCount < 2) {
            revert NotEnoughStakers();
        }
        if (hasVoted[msg.sender]) revert AlreadyVoted();
        if (block.timestamp < deadline) revert DeadlineHasPassed(false);
        if (block.timestamp > deadline + COOLDOWN_PERIOD)
            revert NoInCoolDownPeriod();
        if (_votes.length != stakerCount - 1) revert IncorrectAmountOfVotes();
        for (uint256 i; i < _votes.length; ++i) {
            _checkAndVote(_votes[i]);
        }
        votedCount++;
    }

    function _checkAndVote(Vote calldata _vote) internal {
        if (stakers[_vote.stakerAddr].stakerAddr == address(0))
            revert HasJoined(false);
        if (hasVotedFor[msg.sender][_vote.stakerAddr]) revert AlreadyVoted();
        if (_vote.stakerAddr == msg.sender) revert InvalidVote();

        if (_vote.isUpvote) {
            stakers[_vote.stakerAddr].upVotes++;
        } else {
            stakers[_vote.stakerAddr].downVotes++;
        }

        hasVotedFor[msg.sender][_vote.stakerAddr] = true;
        hasVoted[msg.sender] = true;
    }

    function executePayouts() external {
        if (stakerCount == 0) {
            revert NotEnoughStakers();
        }
        if (stakerCount == 1) {
            stakerIds[0].call{value: address(this).balance}("");
            return;
        }
        if (block.timestamp < deadline + COOLDOWN_PERIOD) {
            revert DeadlineHasPassed(false);
        }
        if (votedCount < (stakerCount + 1) / 2) {
            _executePayback();
        } else {
            _executePayout();
        }
    }

    function _executePayout() internal {
        uint256 _stakeAmount = stakeAmount;
        uint256 _protocolFee = (_stakeAmount * PROTOCOL_FEE) / 10000;
        uint256 _creatorFee = (_stakeAmount * CREATOR_FEE) / 10000;
        uint256 _stakerFee = (_stakeAmount * STAKER_FEE) / 10000;
        _stakeAmount -= (_protocolFee + _creatorFee);

        uint256 nonPassingStakers;

        for (uint256 i; i < stakerCount; ++i) {
            if (
                stakers[stakerIds[i]].upVotes <= stakers[stakerIds[i]].downVotes
            ) {
                nonPassingStakers++;
            }
        }

        bool success;

        if (nonPassingStakers < stakerCount) {
            uint256 amountToDistribute = (_stakeAmount * nonPassingStakers) /
                (stakerCount - nonPassingStakers);
            for (uint256 i; i < stakerCount; ++i) {
                if (
                    stakers[stakerIds[i]].upVotes >
                    stakers[stakerIds[i]].downVotes
                ) {
                    (success, ) = stakerIds[i].call{
                        value: _stakeAmount + amountToDistribute
                    }("");
                    if (!success) revert TransferFailed();
                    IRewardNFT(rewardNFTAddr).mint(
                        stakers[stakerIds[i]].stakerAddr
                    );
                }
            }
        }
        uint256 cummulativeCreatorFee = _creatorFee * stakerCount;

        (success, ) = creator.call{value: cummulativeCreatorFee}("");
        if (!success) revert TransferFailed();

        (success, ) = SquadGoalsAddr.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function _executePayback() internal {
        uint256 _stakeAmount = stakeAmount;
        uint256 _protocolFee = (_stakeAmount * PROTOCOL_FEE) / 10000;
        uint256 _creatorFee = (_stakeAmount * CREATOR_FEE) / 10000;
        _stakeAmount -= (_protocolFee + _creatorFee);
        bool success;
        for (uint256 i; i < stakerCount; ++i) {
            (success, ) = stakerIds[i].call{value: _stakeAmount}("");
            if (!success) revert TransferFailed();
        }

        uint256 cummulativeCreatorFee = _creatorFee * stakerCount;

        (success, ) = creator.call{value: cummulativeCreatorFee}("");
        if (!success) revert TransferFailed();

        (success, ) = SquadGoalsAddr.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function getStaker(
        address _stakerAddr
    ) external view returns (Staker memory) {
        return stakers[_stakerAddr];
    }

    function getStakers() external view returns (Staker[] memory) {
        Staker[] memory _stakers = new Staker[](stakerCount);
        for (uint256 i; i < stakerCount; ++i) {
            _stakers[i] = stakers[stakerIds[i]];
        }
        return _stakers;
    }
}
