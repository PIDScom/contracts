pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "../interface/INameResolver.sol";

import "./AbstractRegistrar.sol";

contract ReverseRegistrar is AbstractRegistrar {
    INameResolver public resolver;
    
    constructor(address ensAddr, address resolverAddr)
        AbstractRegistrar(ensAddr, // namehash("addr.reverse")
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2) {
        
        resolver = INameResolver(resolverAddr);
    }
    
    function claim(address owner) public returns(bytes32) {
        return claimWithResolver(owner, address(0));
    }

    function claimWithResolver(address owner, address _resolver)
        public returns(bytes32) {
        
        bytes32 label = _toSha3Hex(msg.sender);
        bytes32 _node = keccak256(abi.encodePacked(baseNode, label));
        address currentOwner = ens.owner(_node);

        if (_resolver != address(0) && _resolver != ens.resolver(_node)) {
            if (currentOwner != address(this)) {
                ens.setSubnodeOwner(baseNode, label, address(this));
                currentOwner = address(this);
            }
            ens.setResolver(_node, _resolver);
        }

        if (currentOwner != owner) {
            ens.setSubnodeOwner(baseNode, label, owner);
        }

        return _node;
    }
    
    function setName(string memory name) public returns(bytes32) {
        bytes32 _node = claimWithResolver(address(this), address(resolver));
        resolver.setName(_node, name);
        return _node;
    }
    
    function _toSha3Hex(address addr) internal pure returns(bytes32) {
        bytes32 ret;
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

            for { let i := 40 } gt(i, 0) { } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
        
        return ret;
    }
}