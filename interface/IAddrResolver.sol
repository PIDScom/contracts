pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address addr);
    
    function addr(bytes32 node) external view returns(address);
    
    function setAddr(bytes32 node, address addr) external;
}