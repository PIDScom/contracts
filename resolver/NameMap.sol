pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

import "../part/ERC897.sol";
import "../part/Controlable.sol";

import "../registrar/BaseRegistrar.sol";

import "./AbstractResolver.sol";

contract NameMap is ERC897, AbstractResolver, Controlable {
    struct NameInfo {
        string name;
        address nameOwner;
        
        address regAddress;
        uint256 regTokenId;
        address regOwner;
        uint256 registry;
        uint256 expiry;
        
        address avatarAddress;
        uint256 avatarTokenId;
    }
    
    struct BaseInfo {
        string name;
        
        address regAddress;
        uint256 regTokenId;
    }
    
    struct AvatarInfo {
        address addr;
        uint256 tokenId;
    }
    
    mapping(bytes32 => BaseInfo) baseInfos;
    
    mapping(bytes32 => AvatarInfo) avatarInfos;
    
    function setBaseInfo(bytes32 node, string calldata name,
        address regAddress, uint256 regTokenId)
        external onlyController {
        
        BaseInfo storage baseInfo = baseInfos[node];
        baseInfo.name = name;
        baseInfo.regAddress = regAddress;
        baseInfo.regTokenId = regTokenId;
    }
    
    function setAvatar(bytes32 node, address addr, uint256 tokenId)
        external onlyOwnerOrApproval(node) {
        
        require(IERC721(addr).ownerOf(tokenId) == msg.sender,
            "not the owner");
            
        AvatarInfo storage avatarInfo = avatarInfos[node];
        avatarInfo.addr = addr;
        avatarInfo.tokenId = tokenId;
    }
    
    function getBaseInfo(bytes32 node)
        external view returns(BaseInfo memory) {
        
        return baseInfos[node];
    }
    
    function getNameInfo(bytes32 node)
        public view returns(NameInfo memory) {
        
        BaseInfo storage baseInfo = baseInfos[node];
        
        AvatarInfo storage avatarInfo = avatarInfos[node];
        
        NameInfo memory result = NameInfo({
            name: baseInfo.name,
            nameOwner: registry.owner(node),
            
            regAddress: baseInfo.regAddress,
            regTokenId: baseInfo.regTokenId,
            regOwner: address(0),
            registry: 0,
            expiry: 0,
            
            avatarAddress: avatarInfo.addr,
            avatarTokenId: avatarInfo.tokenId
        });
        
        if (baseInfo.regAddress != address(0)) {
            BaseRegistrar reg = BaseRegistrar(baseInfo.regAddress);
            result.registry = reg.nameRegistries(baseInfo.regTokenId);
            result.expiry = reg.nameExpiries(baseInfo.regTokenId);
            
            bytes memory input = abi.encodeWithSignature(
                "ownerOfSuper(uint256)", baseInfo.regTokenId);
            (bool success, bytes memory output) = baseInfo.regAddress.staticcall(input);
            if (success) {
                (result.regOwner) = abi.decode(output, (address));
            }
        }
        
        return result;
    }
    
    function getNameInfos(bytes32[] calldata nodes)
        external view returns(NameInfo[] memory) {
        
        uint256 length = nodes.length;
        NameInfo[] memory result = new NameInfo[](length);
        
        for (uint256 i = 0; i < length; ++i) {
            result[i] = getNameInfo(nodes[i]);
        }
        
        return result;
    }
}