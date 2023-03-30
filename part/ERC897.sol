pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "../interface/IERC897.sol";

contract ERC897 is Ownable, IERC897 {
    address public override implementation;
    uint256 private _proxyType = 2;
    
    receive() external payable {
    }
    
    fallback(bytes calldata input) external payable returns(bytes memory) {
        (bool success, bytes memory output) = implementation.delegatecall(input);
        
        require(success, string(output));
        
        return output;
    }
    
    function proxyType() external override view returns(uint256) {
        return _proxyType;
    }
    
    function setImplementation(address imp) external onlyOwner {
        emit ImplementationChanged(implementation, imp);
        implementation = imp;
    }
    
	/*
    function callContract(address contractAddress, bytes calldata input)
        external payable onlyOwner {
        
        (bool success, bytes memory output) = contractAddress.call(input);
        
    	require(success, string(output));
    }
    
    function callContract(address contractAddress, bytes calldata input, uint256 value)
        external payable onlyOwner {
        
        (bool success, bytes memory output) = contractAddress.call
            {value: value} (input);
        
        require(success, string(output));
    }
	*/
}
