pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract Controlable is Ownable {
    event ControllerChanged(address indexed controller, bool enabled);
    
    mapping(address => bool) internal controllers;
    
    modifier onlyController {
        require(controllers[msg.sender], "not controller");
        _;
    }
    
    function isController(address controller) external view returns(bool) {
        return controllers[controller];
    }
    
    function setController(address controller, bool enabled)
        external onlyOwner {
        
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
    }
}