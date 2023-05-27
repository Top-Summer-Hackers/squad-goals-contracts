# IChallenge
[Git Source](https://github.com/Top-Summer-Hackers/squad-goals-contracts/blob/aff86649437ffe678966a5b8ce508599bbe5f4b2/src/IChallenge.sol)


## Functions
### initialize


```solidity
function initialize(
    uint256 _stakeAmount,
    uint256 _maxAmountOfStakers,
    uint256 _duration,
    address _rewardNFTAddr,
    address _creator
) external;
```

### join


```solidity
function join(bytes32 _name) external payable;
```

### completed


```solidity
function completed() external view returns (bool);
```

### stakeAmount


```solidity
function stakeAmount() external view returns (uint256);
```

### maxAmountOfStakers


```solidity
function maxAmountOfStakers() external view returns (uint256);
```

### deadline


```solidity
function deadline() external view returns (uint256);
```

### stakerCount


```solidity
function stakerCount() external view returns (uint256);
```

### votedCount


```solidity
function votedCount() external view returns (uint256);
```

### getStakers


```solidity
function getStakers() external view returns (Staker[] memory);
```

### onVoting


```solidity
function onVoting() external view returns (bool);
```

## Structs
### Staker

```solidity
struct Staker {
    address stakerAddr;
    bytes32 stakerName;
    uint256 upVotes;
    uint256 downVotes;
}
```

