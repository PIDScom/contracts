pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./lib/Bytes.sol";
import "./lib/UInteger.sol";

contract SignCheck is Ownable {
    using Bytes for bytes;
    using UInteger for uint256;
    
    address public account;
    
    function setAccount(address acc) external onlyOwner {
        account = acc;
    }
    
    function checkSignature(bytes memory message, uint8 v, bytes32 r, bytes32 s)
        public view returns(bool) {
        
        bytes memory bs = bytes("\x19Ethereum Signed Message:\n")
            .concat(message.length.toDecBytes())
            .concat(message);
        
        bytes32 hash = keccak256(bs);
        return ecrecover(hash, v, r, s) == account;
    }
    
    function requireSignature(bytes memory message, uint8 v, bytes32 r, bytes32 s)
        public view {
        
        require(checkSignature(message, v, r, s), "invalid signature");
    }
}
