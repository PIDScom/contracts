pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

interface IERC897 {
    event ImplementationChanged(address indexed oldImp, address indexed newImp);
    
    function proxyType() external view returns(uint256);
    
    function implementation() external view returns(address);
}