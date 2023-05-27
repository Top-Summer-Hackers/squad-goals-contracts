pragma solidity 0.8.19;
import "./IRewardNFT.sol";
import "./IChallenge.sol";

/**
 * @title ChallengeImplementation
 * @notice The implementation contract for a Challenge
 * @author Carlos Ramos
 */
contract ChallengeImplementation is IChallenge {
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
    uint256 public override stakeAmount;
    uint256 public override maxAmountOfStakers;
    uint256 public override deadline;
    uint256 public override stakerCount = 0;
    uint256 public override votedCount;

    mapping(address => Staker) stakers;
    mapping(uint256 => address) stakerIds;
    mapping(address => bool) public hasVoted;
    mapping(address => mapping(address => bool)) public hasVotedFor;
    bool private initialized;
    bool public override completed;

    /**
     * @notice Initializes the Challenge
     * @param _stakeAmount The amount of ETH to stake
     * @param _maxAmountOfStakers The maximum amount of stakers
     * @param _duration The duration of the Challenge
     * @param _rewardNFTAddr The address of the RewardNFT
     * @param _creator The address of the creator of the Challenge
     * @dev This function can only be called once
     */
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

    modifier whenNotCompleted() {
        require(!completed, "Challenge : Already completed");
        _;
    }

    function join(bytes32 _name) external payable override whenNotCompleted {
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

    /**
     * @notice Allows a staker to vote on the Challenge
     * @param _votes The votes to be submitted
     * the length is stakerCount - 1, the address of msg.sender shouldnt be included
     */
    function submitVote(Vote[] calldata _votes) external whenNotCompleted {
        if (stakers[msg.sender].stakerAddr == address(0)) {
            revert HasJoined(false);
        }
        if (stakerCount < 2) {
            revert NotEnoughStakers();
        }
        if (hasVoted[msg.sender]) revert AlreadyVoted();
        if (!onVoting()) revert NoInCoolDownPeriod();
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

    function executePayouts() external whenNotCompleted {
        if (block.timestamp < deadline + COOLDOWN_PERIOD) {
            revert DeadlineHasPassed(false);
        }
        if (stakerCount == 0) {
            revert NotEnoughStakers();
        }
        if (stakerCount == 1) {
            stakerIds[0].call{value: address(this).balance}("");
            return;
        }
        if (votedCount < (stakerCount + 1) / 2) {
            _executePayback();
        } else {
            _executePayout();
        }
        completed = true;
    }

    function _executePayout() internal {
        uint256 _stakeAmount = stakeAmount;
        uint256 _protocolFee = (_stakeAmount * PROTOCOL_FEE) / 10000;
        uint256 _creatorFee = (_stakeAmount * CREATOR_FEE) / 10000;
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

    function getStakers() external view override returns (Staker[] memory) {
        Staker[] memory _stakers = new Staker[](stakerCount);
        for (uint256 i; i < stakerCount; ++i) {
            _stakers[i] = stakers[stakerIds[i]];
        }
        return _stakers;
    }

    function onVoting() public view virtual returns (bool) {
        return (block.timestamp > deadline &&
            block.timestamp < deadline + COOLDOWN_PERIOD);
    }
}
