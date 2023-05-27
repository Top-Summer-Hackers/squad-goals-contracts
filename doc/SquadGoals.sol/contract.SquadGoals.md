# SquadGoals
[Git Source](https://github.com/Top-Summer-Hackers/squad-goals-contracts/blob/aff86649437ffe678966a5b8ce508599bbe5f4b2/src/SquadGoals.sol)

**Author:**
Carlos Ramos


## State Variables
### treasury

```solidity
address public treasury;
```


### challengeImplementation

```solidity
address public challengeImplementation;
```


### challenges

```solidity
mapping(uint256 => address) public challenges;
```


### challengeInitData

```solidity
mapping(uint256 => bytes) public challengeInitData;
```


### challengeNFT

```solidity
mapping(address => address) public challengeNFT;
```


### challengeCopys

```solidity
mapping(uint256 => address) public challengeCopys;
```


### challengeCopyNFT

```solidity
mapping(address => address) public challengeCopyNFT;
```


### copiesOfChallengeId

```solidity
mapping(uint256 => address[]) public copiesOfChallengeId;
```


### challengeCount

```solidity
uint256 public challengeCount = 1;
```


### copyCount

```solidity
uint256 public copyCount = 1;
```


## Functions
### constructor


```solidity
constructor(address _treasury, address _challengeImplementation);
```

### createChallenge

*This function deploys a new proxy and assigns the basic implementation of Challenge*

*this function will deploy a new RewardNFT and assign it to the Challenge*


```solidity
function createChallenge(
    uint256 _stakeAmount,
    uint256 _maxAmountOfStakers,
    uint256 _duration,
    string memory _name,
    string memory _symbol,
    string memory _uri
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_stakeAmount`|`uint256`|The amount of ETH to stake|
|`_maxAmountOfStakers`|`uint256`|The maximum amount of stakers|
|`_duration`|`uint256`|The duration of the Challenge|
|`_name`|`string`|The name of the RewardNFT|
|`_symbol`|`string`|The symbol of the RewardNFT|
|`_uri`|`string`|The uri of the RewardNFT|


### createChallengeCopy


```solidity
function createChallengeCopy(uint256 _challengeId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_challengeId`|`uint256`|the id of the challenge to copy|


### withdraw


```solidity
function withdraw() external;
```

### getChallenge


```solidity
function getChallenge(uint256 _challengeId) public view returns (address, address);
```

### getChallengeCopy


```solidity
function getChallengeCopy(uint256 _challengeId) public view returns (address, address);
```

### getUserClaimedNFTs


```solidity
function getUserClaimedNFTs(address _user) external view returns (UserClaimedNFT[] memory claimedNFTs);
```

### getChallenges


```solidity
function getChallenges() public view returns (ChallengeReturnData[] memory openChallenges);
```

### getChallengeCopies


```solidity
function getChallengeCopies() public view returns (ChallengeReturnData[] memory openChallenges);
```

### getCopiesOfChallenge


```solidity
function getCopiesOfChallenge(uint256 _challengeId) external view returns (address[] memory);
```

### getAllChallenges


```solidity
function getAllChallenges()
    external
    view
    returns (ChallengeReturnData[] memory openChallenges, ChallengeReturnData[] memory openChallengeCopies);
```

### receive


```solidity
receive() external payable;
```

## Events
### ChallengeCreated

```solidity
event ChallengeCreated(address challenge);
```

## Errors
### NotEnoughBalance

```solidity
error NotEnoughBalance();
```

### TransferFailed

```solidity
error TransferFailed();
```

### ChallengeDoesntExist

```solidity
error ChallengeDoesntExist();
```

## Structs
### UserClaimedNFT

```solidity
struct UserClaimedNFT {
    address NFT;
    uint256[] tokenIds;
}
```

### ChallengeReturnData

```solidity
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
```

