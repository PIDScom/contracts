pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

library UInteger {
    function toString(uint256 a, uint256 radix)
        internal pure returns(string memory) {
        
        if (a == 0) {
            return "0";
        }
        
        uint256 length = 0;
        for (uint256 n = a; n != 0; n /= radix) {
            ++length;
        }
        
        bytes memory bs = new bytes(length);
        
        while (a != 0) {
            uint256 b = a % radix;
            a /= radix;
            
            if (b < 10) {
                bs[--length] = bytes1(uint8(b + 48));
            } else {
                bs[--length] = bytes1(uint8(b + 87));
            }
        }
        
        return string(bs);
    }
    
    function toString(uint256 a) internal pure returns(string memory) {
        return UInteger.toString(a, 10);
    }
    
    function toDecBytes(uint256 n) internal pure returns(bytes memory) {
        if (n == 0) {
            return bytes("0");
        }
        
        uint256 length = 0;
        for (uint256 m = n; m > 0; m /= 10) {
            ++length;
        }
        
        bytes memory bs = new bytes(length);
        
        while (n > 0) {
            uint256 m = n % 10;
            n /= 10;
            
            bs[--length] = bytes1(uint8(m + 48));
        }
        
        return bs;
    }
}
