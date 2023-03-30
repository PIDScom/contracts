pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/interfaces/IERC165.sol";

import "../interface/IENS.sol";

abstract contract AbstractResolver is Ownable, IERC165 {
    IENS internal registry;
    
    modifier onlyOwnerOrApproval(bytes32 node) {
        require(registry.isOwnerOrApproval(msg.sender, node),
            "not owner or approval");
            
        _;
    }
    
    function setRegistry(address registryAddr) external onlyOwner {
        registry = IENS(registryAddr);
    }
    
    function supportsInterface(bytes4 interfaceID)
        public override virtual pure returns(bool) {
        
        return interfaceID == IERC165.supportsInterface.selector;
    }
}