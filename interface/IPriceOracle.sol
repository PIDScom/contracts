pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

interface IPriceOracle {
    function price(string calldata name, uint256 duration)
        external view returns(uint256);
        
    function unitPrice(string calldata name, uint256 duration)
        external view returns(uint256);
        
    function convert(uint256 amount) external view returns(uint256);
}