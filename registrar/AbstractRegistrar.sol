pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "../interface/IENS.sol";

abstract contract AbstractRegistrar {
    IENS public ens;
    
    bytes32 public baseNode;
    
    constructor(address ensAddr, bytes32 _baseNode) {
        ens = IENS(ensAddr);
        baseNode = _baseNode;
    }
}