pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "../lib/Bytes.sol";
import "../lib/String.sol";

import "../part/Controlable.sol";
import "../part/ERC721Ex.sol";

import "../resolver/NameMap.sol";

import "./AbstractRegistrar.sol";

contract BaseRegistrar is AbstractRegistrar, ERC721Ex, Controlable {
    using Bytes for bytes;
    using String for string;
    
    event NameMigrated(uint256 indexed id, address indexed owner, uint256 expiries);
    event NameRegistered(uint256 indexed id, address indexed owner, uint256 expiries);
    event NameRenewed(uint256 indexed id, uint256 expiries);
    
    event Nested(uint256 indexed tokenId);
    event Unnested(uint256 indexed tokenId);
    event Expelled(uint256 indexed tokenId);
    
    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ERC721_ID = bytes4(
        keccak256("balanceOf(address)") ^
        keccak256("ownerOf(uint256)") ^
        keccak256("approve(address,uint256)") ^
        keccak256("getApproved(uint256)") ^
        keccak256("setApprovalForAll(address,bool)") ^
        keccak256("isApprovedForAll(address,address)") ^
        keccak256("transferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256,bytes)")
    );
    bytes4 constant private RECLAIM_ID = bytes4(keccak256("reclaim(uint256,address)"));
    
    string public baseName;
    
    NameMap nameMap;
    
    // A map of registry times
    mapping(uint256 => uint256) registries;
    
    // A map of expiry times
    mapping(uint256 => uint256) expiries;
    
    uint256 public gracePeriod = 90 days;
    
    mapping(address => bool) public operatorBlackLists;
    
    bool public nestingOpen;
    mapping(uint256 => uint256) private nestingStarted;
    mapping(uint256 => uint256) private nestingTotal;
    bool private nestingTransfer;
    
    constructor(address _ens, bytes32 _baseNode, string memory _baseName,
        string memory _name, string memory _symbol)
        AbstractRegistrar(_ens, _baseNode)
        ERC721(_name, _symbol) {
        
        baseName = _baseName;
        baseNode = _baseNode;
    }

    modifier live {
        require(ens.owner(baseNode) == address(this), "not live");
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expiries.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public override view returns(address) {
        require(expiries[tokenId] > block.timestamp, "expired");
        return super.ownerOf(tokenId);
    }
    
    function ownerOfSuper(uint256 tokenId) public view returns(address) {
        return super.ownerOf(tokenId);
    }
    
    function setGracePeriod(uint256 period) external onlyOwner {
        gracePeriod = period;
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external onlyOwner {
        ens.setResolver(baseNode, resolver);
    }
    
    function setNameMap(address nm) external onlyOwner {
        nameMap = NameMap(payable(nm));
    }

    // Returns the registration timestamp of the specified id.
    function nameRegistries(uint256 id) external view returns(uint256) {
        return registries[id];
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpiries(uint256 id) external view returns(uint256) {
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns(bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + gracePeriod < block.timestamp;
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(uint256 id, address owner, uint256 duration)
        external returns(uint256) {
        
        return _register(id, owner, duration, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(uint256 id, address owner, uint256 duration) external returns(uint256) {
      return _register(id, owner, duration, false);
    }

    function _register(uint256 id, address owner, uint256 duration, bool updateRegistry)
        internal live onlyController returns(uint256) {
        
        require(available(id), "not available");

        registries[id] = block.timestamp;
        expiries[id] = block.timestamp + duration;
        
        if(_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
        if(updateRegistry) {
            ens.setSubnodeOwner(baseNode, bytes32(id), owner);
        }

        emit NameRegistered(id, owner, block.timestamp + duration);

        return block.timestamp + duration;
    }

    function renew(uint256 id, uint256 duration)
        external live onlyController returns(uint256) {
        
        // Name must be registered here or in grace period
        require(expiries[id] + gracePeriod >= block.timestamp, "expired");

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external live {
        require(_isApprovedOrOwner(msg.sender, id), "not approved or owner");
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function supportsInterface(bytes4 interfaceID)
        public override pure returns(bool) {
        
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == ERC721_ID ||
               interfaceID == RECLAIM_ID;
    }
    
    function setOperatorBlackList(address[] memory addresses, bool enabled)
        external onlyOwner {
        
        for (uint256 i = 0; i < addresses.length; ++i) {
            operatorBlackLists[addresses[i]] = enabled;
        }
    }
    
    function approve(address to, uint256 tokenId) public override {
        require(!operatorBlackLists[to], "in blacklist");
        super.approve(to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved)
        public override {
        
        require(!operatorBlackLists[operator], "in blacklist");
        super.setApprovalForAll(operator, approved);
    }
    
    function setNestingOpen(bool open) external onlyOwner {
        nestingOpen = open;
    }
    
    function nestingPeriod(uint256 tokenId)
        external view returns(bool, uint256, uint256){
        
        bool nesting = false;
        uint256 current = 0;
        
        uint256 start = nestingStarted[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        
        uint256 total = current + nestingTotal[tokenId];
        
        return (nesting, current, total);
    }
    
    function toggleNesting(uint256 tokenId)
        public onlyApprovedOrOwner(tokenId) {
        
        uint256 start = nestingStarted[tokenId];
        if (start == 0) {
            require(nestingOpen, "nesting closed");
            nestingStarted[tokenId] = block.timestamp;
            emit Nested(tokenId);
        } else {
            nestingTotal[tokenId] += block.timestamp - start;
            nestingStarted[tokenId] = 0;
            emit Unnested(tokenId);
        }
    }
    
    function toggleNesting(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            toggleNesting(tokenIds[i]);
        }
    }
    
    function expelFromNest(uint256 tokenId) external onlyOwner {
        require(nestingStarted[tokenId] != 0, "not nested");
        nestingTotal[tokenId] += block.timestamp - nestingStarted[tokenId];
        nestingStarted[tokenId] = 0;
        emit Unnested(tokenId);
        emit Expelled(tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(from == msg.sender || !operatorBlackLists[from],
            "in blacklist");
            
        require(nestingStarted[tokenId] == 0 || nestingTransfer,
            "nesting");
        
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public view override returns(string memory) {
        
        require(_exists(tokenId), "nonexistent token");
        
        uint256 registry = registries[tokenId];
        uint256 expiry = expiries[tokenId];
        
        bytes32 node = keccak256(abi.encodePacked(baseNode, tokenId));
        NameMap.BaseInfo memory baseInfo = nameMap.getBaseInfo(node);
        
        bytes memory data = abi.encodePacked(registry, expiry, baseInfo.name);
        
        return _baseURI().concat(data.base64Encode());
    }
}