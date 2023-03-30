pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);
    
    function name(bytes32 node) external view returns(string memory);
    
    function setName(bytes32 node, string memory name) external;
}