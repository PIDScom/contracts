pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

library String {
    function equals(string memory a, string memory b)
        internal pure returns(bool) {
        
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        
        if (ba.length != bb.length) {
            return false;
        }
        
        uint256 length = ba.length;
        
        for (uint256 i = 0; i < length; ++i) {
            if (ba[i] != bb[i]) {
                return false;
            }
        }
        
        return true;
    }
    
    function concat(string memory a, string memory b)
        internal pure returns(string memory) {
        
        return string(abi.encodePacked(a, b));
    }
    
    function utf8length(string memory s) internal pure returns(uint256) {
        bytes memory bs = bytes(s);
        uint256 bytelength = bs.length;
        uint256 length = 0;
        
        for (uint256 i = 0; i < bytelength; ++length) {
            bytes1 b = bs[i];
            
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        
        return length;
    }
    
    // . for \u2e
    // zero width for \u200b \u200c \u200d and \ufeff
    function checkName(string memory name) internal pure returns(bool) {
        bytes memory bs = bytes(name);
        uint256 bytelength = bs.length - 2;
        
        for (uint256 i = 0; i < bytelength; ++i) {
            bytes1 b = bytes1(bs[i]);
            
            if (b == 0x2e) {
                return false;
            } else if (b == 0xe2) {
                if (bytes1(bs[i + 1]) == 0x80 && (
                    bytes1(bs[i + 2]) == 0x8b ||
                    bytes1(bs[i + 2]) == 0x8c ||
                    bytes1(bs[i + 2]) == 0x8d)
                ) {
                    return false;
                }
            } else if (b == 0xef) {
                if (bytes1(bs[i + 1]) == 0xbb && bytes1(bs[i + 2]) == 0xbf) {
                    return false;
                }
            }
        }
        
        return true;
    }
}
