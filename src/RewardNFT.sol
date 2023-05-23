pragma solidity ^0.8.19;
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract RewardNFT is ERC721, Ownable {
    error NotTransferrable();

    string uri;
    uint256 tokenIds = 1;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        uri = _uri;
    }

    function mint(address _to) external onlyOwner {
        _mint(_to, tokenIds);
        tokenIds++;
    }

    function _transfer(address, address, uint256) internal override {
        revert NotTransferrable();
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }
}
