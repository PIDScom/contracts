pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract FixedTimers is Ownable {
    struct Timer {
        uint256 startTime;
        uint256 endTime;
    }
    
    mapping(string => Timer) public fixedTimers;
    
    modifier onlyFixedTimes(string memory key) {
        require(isFixedTimes(key), "not in fixed time");
        
        _;
    }
    
    function isFixedTimes(string memory key) public view returns(bool) {
        Timer storage timer = fixedTimers[key];
        return block.timestamp >= timer.startTime && block.timestamp <= timer.endTime;
    }
    
    function setFixedTimes(string memory key, Timer memory timer)
        external onlyOwner {
        
        fixedTimers[key] = timer;
    }
}
