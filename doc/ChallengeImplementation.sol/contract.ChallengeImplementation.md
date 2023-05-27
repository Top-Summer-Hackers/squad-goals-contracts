# ChallengeImplementation
[Git Source](https://github.com/Top-Summer-Hackers/squad-goals-contracts/blob/aff86649437ffe678966a5b8ce508599bbe5f4b2/src/ChallengeImplementation.sol)

**Inherits:**
[IChallenge](/src/IChallenge.sol/contract.IChallenge.md)

**Author:**
Carlos Ramos

The implementation contract for a Challenge


## State Variables
### CREATOR_FEE

```solidity
uint256 constant CREATOR_FEE = 1000;
```


### PROTOCOL_FEE

```solidity
uint256 constant PROTOCOL_FEE = 1000;
```


### STAKER_FEE

```solidity
uint256 constant STAKER_FEE = 8000;
```


### COOLDOWN_PERIOD

```solidity
uint256 constant COOLDOWN_PERIOD = 3 days;
```


### creator

```solidity
address creator;
```


### SquadGoalsAddr

```solidity
address SquadGoalsAddr;
```


### rewardNFTAddr

```solidity
address rewardNFTAddr;
```


### stakeAmount

```solidity
uint256 public override stakeAmount;
```


### maxAmountOfStakers

```solidity
uint256 public override maxAmountOfStakers;
```


### deadline

```solidity
uint256 public override deadline;
```


### stakerCount

```solidity
uint256 public override stakerCount = 0;
```


### votedCount

```solidity
uint256 public override votedCount;
```


### stakers

```solidity
mapping(address => Staker) stakers;
```


### stakerIds

```solidity
mapping(uint256 => address) stakerIds;
```


### hasVoted

```solidity
mapping(address => bool) public hasVoted;
```


### hasVotedFor

```solidity
mapping(address => mapping(address => bool)) public hasVotedFor;
```


### initialized

```solidity
bool private initialized;
```


### completed

```solidity
bool public override completed;
```


## Functions
### initialize

Initializes the Challenge

*This function can only be called once*


```solidity
function initialize(
    uint256 _stakeAmount,
    uint256 _maxAmountOfStakers,
    uint256 _duration,
    address _rewardNFTAddr,
    address _creator
) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_stakeAmount`|`uint256`|The amount of ETH to stake|
|`_maxAmountOfStakers`|`uint256`|The maximum amount of stakers|
|`_duration`|`uint256`|The duration of the Challenge|
|`_rewardNFTAddr`|`address`|The address of the RewardNFT|
|`_creator`|`address`|The address of the creator of the Challenge|


### whenNotCompleted


```solidity
modifier whenNotCompleted();
```

### join


```solidity
function join(bytes32 _name) external payable override whenNotCompleted;
```

### submitVote

Allows a staker to vote on the Challenge


```solidity
function submitVote(Vote[] calldata _votes) external whenNotCompleted;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_votes`|`Vote[]`|The votes to be submitted the length is stakerCount - 1, the address of msg.sender shouldnt be included|


### _checkAndVote


```solidity
function _checkAndVote(Vote calldata _vote) internal;
```

### executePayouts


```solidity
function executePayouts() external whenNotCompleted;
```

### _executePayout


```solidity
function _executePayout() internal;
```

### _executePayback


```solidity
function _executePayback() internal;
```

### getStaker


```solidity
function getStaker(address _stakerAddr) external view returns (Staker memory);
```

### getStakers


```solidity
function getStakers() external view override returns (Staker[] memory);
```

### onVoting


```solidity
function onVoting() public view virtual returns (bool);
```

## Errors
### ContractAlreadyInitialized

```solidity
error ContractAlreadyInitialized();
```

### MaxAmountOfStakersReached

```solidity
error MaxAmountOfStakersReached();
```

### IncorrectAmountOfEthSent

```solidity
error IncorrectAmountOfEthSent();
```

### DeadlineHasPassed

```solidity
error DeadlineHasPassed(bool);
```

### HasJoined

```solidity
error HasJoined(bool);
```

### NoInCoolDownPeriod

```solidity
error NoInCoolDownPeriod();
```

### IncorrectAmountOfVotes

```solidity
error IncorrectAmountOfVotes();
```

### AlreadyVoted

```solidity
error AlreadyVoted();
```

### InvalidVote

```solidity
error InvalidVote();
```

### TransferFailed

```solidity
error TransferFailed();
```

### NotEnoughStakers

```solidity
error NotEnoughStakers();
```

## Structs
### Vote

```solidity
struct Vote {
    address stakerAddr;
    bool isUpvote;
}
```

