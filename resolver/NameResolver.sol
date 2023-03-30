pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "../interface/INameResolver.sol";

import "./AbstractResolver.sol";

contract NameResolver is AbstractResolver, INameResolver {
    mapping(bytes32 => string) internal names;
    
    function name(bytes32 node)
        external override view returns(string memory) {
        
        return names[node];
    }
    
    function setName(bytes32 node, string calldata newName)
        external override onlyOwnerOrApproval(node) {
        
        names[node] = newName;
        emit NameChanged(node, newName);
    }
    
    function supportsInterface(bytes4 interfaceID)
        public override pure returns(bool) {
        
        if (interfaceID == INameResolver.name.selector) {
            return true;
        } else {
            return super.supportsInterface(interfaceID);
        }
    }
}