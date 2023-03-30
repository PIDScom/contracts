pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

library Bytes {
    bytes internal constant BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    
    function base64Encode(bytes memory bs) internal pure returns(string memory) {
        uint256 remain = bs.length % 3;
        uint256 length = bs.length / 3 * 4;
        bytes memory result = new bytes(length + (remain != 0 ? 4 : 0) + (3 - remain) % 3);
        
        uint256 i = 0;
        uint256 j = 0;
        while (i < length) {
            result[i++] = BASE64_CHARS[uint8(bs[j] >> 2)];
            result[i++] = BASE64_CHARS[uint8((bs[j] & 0x03) << 4 | bs[j + 1] >> 4)];
            result[i++] = BASE64_CHARS[uint8((bs[j + 1] & 0x0f) << 2 | bs[j + 2] >> 6)];
            result[i++] = BASE64_CHARS[uint8(bs[j + 2] & 0x3f)];
            
            j += 3;
        }
        
        if (remain != 0) {
            result[i++] = BASE64_CHARS[uint8(bs[j] >> 2)];
            
            if (remain == 2) {
                result[i++] = BASE64_CHARS[uint8((bs[j] & 0x03) << 4 | bs[j + 1] >> 4)];
                result[i++] = BASE64_CHARS[uint8((bs[j + 1] & 0x0f) << 2)];
                result[i++] = BASE64_CHARS[0];
                result[i++] = 0x3d;
            } else {
                result[i++] = BASE64_CHARS[uint8((bs[j] & 0x03) << 4)];
                result[i++] = BASE64_CHARS[0];
                result[i++] = BASE64_CHARS[0];
                result[i++] = 0x3d;
                result[i++] = 0x3d;
            }
        }
        
        return string(result);
    }
    
    function concat(bytes memory a, bytes memory b)
        internal pure returns(bytes memory) {
        
        return abi.encodePacked(a, b);
    }
}
