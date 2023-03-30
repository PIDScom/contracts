pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "../interface/IAddrResolver.sol";

import "./AbstractResolver.sol";

contract AddrResolver is AbstractResolver, IAddrResolver {
    mapping(bytes32 => address) internal addresses;
    
    function addr(bytes32 node) external override view returns(address) {
        return addresses[node];
    }
    
    function setAddr(bytes32 node, address newAddr)
        external override onlyOwnerOrApproval(node) {
        
        addresses[node] = newAddr;
        emit AddrChanged(node, newAddr);
    }
    
    function supportsInterface(bytes4 interfaceID)
        public override pure returns(bool) {
        
        if (interfaceID == IAddrResolver.addr.selector) {
            return true;
        } else {
            return super.supportsInterface(interfaceID);
        }
    }
}