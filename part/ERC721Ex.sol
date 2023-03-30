pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

import "../interface/IERC721TokenReceiverEx.sol";

abstract contract ERC721Ex is ERC721Enumerable, Ownable {
    using Address for address;
    
    string internal __baseURI;
    
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId),
            "not approved");
            
        _;
    }
    
    // [startIndex, endIndex)
    function tokensOf(address owner, uint256 startIndex, uint256 endIndex)
        public view returns(uint256[] memory) {
        
        require(owner != address(0), "owner is zero address");
        
        if (endIndex == 0) {
            endIndex = balanceOf(owner);
        }
        
        uint256[] memory result = new uint256[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; ++i) {
            result[i - startIndex] = tokenOfOwnerByIndex(owner, i);
        }
        
        return result;
    }
    
    function tokensOf(address owner) external view returns(uint256[] memory) {
        return tokensOf(owner, 0, 0);
    }
    
    function safeBatchTransferFrom(address from, address to,
        uint256[] memory tokenIds) external {
        
        safeBatchTransferFrom(from, to, tokenIds, "");
    }
    
    function safeBatchTransferFrom(address from, address to,
        uint256[] memory tokenIds, bytes memory data) public {
        
        batchTransferFrom(from, to, tokenIds);
        
        if (to.isContract()) {
            require(IERC721TokenReceiverEx(to)
                .onERC721ExReceived(msg.sender, from, tokenIds, data)
                == IERC721TokenReceiverEx.onERC721ExReceived.selector,
                "onERC721ExReceived() return invalid");
        }
    }
    
    function batchTransferFrom(address from, address to,
        uint256[] memory tokenIds) public {
        
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            transferFrom(from, to, tokenIds[i]);
        }
    }
    
    function _baseURI() internal view override returns(string memory) {
        return __baseURI;
    }
    
    function setBaseURI(string calldata baseURI) external onlyOwner {
        __baseURI = baseURI;
    }
}
