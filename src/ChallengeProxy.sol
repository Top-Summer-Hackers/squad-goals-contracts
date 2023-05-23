pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/proxy/Proxy.sol";

contract ChallengeProxy is Proxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private implementationSlot =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address _logic) {
        bytes32 slot = implementationSlot;
        assembly {
            sstore(slot, _logic)
        }
    }

    function _implementation() internal view override returns (address logic) {
        bytes32 slot = implementationSlot;
        assembly {
            logic := sload(slot)
        }
    }
}
