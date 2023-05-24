pragma solidity ^0.8.19;
import "forge-std/Test.sol";
import "../src/ChallengeImplementation.sol";
import "../src/RewardNFT.sol";

contract RewardNFTTest is Test {
    RewardNFT rewardNFT;

    address account1 = vm.addr(1);
    address account2 = vm.addr(2);

    function setUp() public {
        rewardNFT = new RewardNFT("name", "symbol", "uri");
    }

    function testMintOnlyOwner() public {
        vm.prank(account2);
        vm.expectRevert("Ownable: caller is not the owner");
        rewardNFT.mint(account1);
    }

    function testTranferDoesntWork() public {
        rewardNFT.mint(account1);
        vm.prank(account1);
        rewardNFT.approve((address(this)), 1);
        vm.expectRevert(abi.encodeWithSignature("NotTransferrable()"));
        rewardNFT.transferFrom(account1, account2, 1);
    }

    function testUri() public {
        require(
            keccak256(bytes(rewardNFT.tokenURI(1))) == keccak256(bytes("uri"))
        );
    }
}
