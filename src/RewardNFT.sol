pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract RewardNFT is ERC721Enumerable, Ownable {
    error NotTransferrable();

    string uri;
    uint256 tokenIds = 1;
    mapping(address => bool) public isAuthorizedMinter;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        uri = _uri;
    }

    modifier onlyAuthorizedMinter() {
        require(
            isAuthorizedMinter[msg.sender],
            "RewardNFT : Not authorized minter"
        );
        _;
    }

    function setAuthorizedMinter(address _minter) external onlyOwner {
        isAuthorizedMinter[_minter] = true;
    }

    function removeAuthorizedMinter(address _minter) external onlyOwner {
        isAuthorizedMinter[_minter] = false;
    }

    function mint(address _to) external onlyAuthorizedMinter {
        _mint(_to, tokenIds);
        tokenIds++;
    }

    function _transfer(address, address, uint256) internal pure override {
        revert NotTransferrable();
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }
}
