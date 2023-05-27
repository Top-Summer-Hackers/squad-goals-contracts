# ChallengeProxy
[Git Source](https://github.com/Top-Summer-Hackers/squad-goals-contracts/blob/aff86649437ffe678966a5b8ce508599bbe5f4b2/src/ChallengeProxy.sol)

**Inherits:**
Proxy

**Author:**
Carlos Ramos

A simple proxy contract to be used for the Challenge contract


## State Variables
### IMPLEMENTATION_SLOT
*Storage slot with the address of the current implementation.
This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
validated in the constructor.*


```solidity
bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
```


## Functions
### constructor


```solidity
constructor(address _logic);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_logic`|`address`|The address of the initial implementation.|


### _implementation


```solidity
function _implementation() internal view override returns (address logic);
```

### getImplementation


```solidity
function getImplementation() external view returns (address);
```

