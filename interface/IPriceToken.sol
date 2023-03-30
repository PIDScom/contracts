pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

interface IPriceToken {
    function read() external view returns(bytes32);
    
    function latestAnswer() external view returns(int256);
}
