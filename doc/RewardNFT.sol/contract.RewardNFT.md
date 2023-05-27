# RewardNFT
[Git Source](https://github.com/Top-Summer-Hackers/squad-goals-contracts/blob/aff86649437ffe678966a5b8ce508599bbe5f4b2/src/RewardNFT.sol)

**Inherits:**
ERC721Enumerable, Ownable


## State Variables
### uri

```solidity
string uri;
```


### tokenIds

```solidity
uint256 tokenIds = 1;
```


### isAuthorizedMinter

```solidity
mapping(address => bool) public isAuthorizedMinter;
```


## Functions
### constructor


```solidity
constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol);
```

### onlyAuthorizedMinter


```solidity
modifier onlyAuthorizedMinter();
```

### setAuthorizedMinter


```solidity
function setAuthorizedMinter(address _minter) external onlyOwner;
```

### removeAuthorizedMinter


```solidity
function removeAuthorizedMinter(address _minter) external onlyOwner;
```

### mint


```solidity
function mint(address _to) external onlyAuthorizedMinter;
```

### _transfer


```solidity
function _transfer(address, address, uint256) internal pure override;
```

### tokenURI


```solidity
function tokenURI(uint256) public view override returns (string memory);
```

## Errors
### NotTransferrable

```solidity
error NotTransferrable();
```

