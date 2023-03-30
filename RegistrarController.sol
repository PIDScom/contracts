pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

import "./interface/IAddrResolver.sol";
import "./interface/IPriceOracle.sol";

import "./lib/String.sol";

import "./part/Controlable.sol";
import "./part/ERC897.sol";
import "./part/FixedTimers.sol";

import "./registrar/BaseRegistrar.sol";

import "./resolver/NameMap.sol";

import "./SignCheck.sol";

contract RegistrarController is ERC897, Controlable, FixedTimers, IERC1155Receiver {
    using Address for address;
    using String for string;
    
    struct NFTWhiteList {
        address nft;
        uint256[] tokenIds;
        uint256[] mintCounts;
    }
    
    struct RegistrarParams {
        string name;
        uint256 numberMin;
        address owner;
        uint256 duration;
        bytes32 secret;
        address resolver;
    }
    
    event NameRegistered(string name, bytes32 indexed label,
        address indexed owner, uint256 cost, uint256 expires);
    event NameRenewed(string name, bytes32 indexed label,
        uint256 cost, uint256 expires);
    event NewPriceOracle(address indexed oracle);
    
    uint256 constant public MINT_FREE_DURATION = 365 days;

    BaseRegistrar base;
    NameMap nameMap;
    
    IPriceOracle priceOracle;
    
    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;
    
    mapping(bytes32 => uint256) public commitments;
    
    SignCheck internal signCheck;
    mapping(uint256 => bool) public ogUseds;
    
    IERC1155 public WTicket;
    uint256[] public WTicketPrices;
    
    mapping(address => mapping(uint256 => uint256)) public nftMintCounts;
    
    function setBase(address _base) external onlyOwner {
        base = BaseRegistrar(_base);
    }
    
    function setNameMap(address nm) external onlyOwner {
        nameMap = NameMap(payable(nm));
    }
    
    function setPriceOracle(address po) external onlyOwner {
        priceOracle = IPriceOracle(po);
        emit NewPriceOracle(po);
    }
    
    function setCommitmentAges(uint256 min, uint256 max)
        external onlyOwner {
        
        minCommitmentAge = min;
        maxCommitmentAge = max;
    }
    
    function setSignCheck(address sc) external onlyOwner {
        signCheck = SignCheck(sc);
    }
    
    function setWTicket(address w) external onlyOwner {
        WTicket = IERC1155(w);
    }
    
    function setWTicketPrices(uint256[] memory prices) external onlyOwner {
        WTicketPrices = prices;
    }
    
    function vaild(string memory name, uint256 numberMin)
        public pure returns(bool) {
        
        uint256 length = name.utf8length();
        if (length < 3 || length > 64) {
            return false;
        }
        
        if (numberMin < type(uint256).max) {
            bytes memory bs = bytes(name);
            
            bool numberOnly = true;
            for (uint256 i = 0; i < bs.length; ++i) {
                uint8 b = uint8(bs[i]);
                if (b < 48 || b > 57) {
                    numberOnly = false;
                    break;
                }
            }
            
            if (numberOnly && length < numberMin) {
                return false;
            }
        }
        
        return name.checkName();
    }
    
    function available(string memory name) public view returns(bool) {
        bytes32 label = keccak256(bytes(name));
        return base.available(uint256(label));
    }
    
    function makeCommitment(string memory name, address owner, bytes32 secret)
        public pure returns(bytes32) {
        
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(string memory name,
        address owner, bytes32 secret, address resolver, address addr)
        public pure returns(bytes32) {
        
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0), "resolver is null");
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) external onlyFixedTimes("commit") {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp,
            "commited");
        commitments[commitment] = block.timestamp;
    }
    
    function _register(RegistrarParams memory rp) internal {
        require(vaild(rp.name, rp.numberMin), "name invaild");
        
        uint256 cost = _consumeCommitment(rp.name, rp.owner, rp.duration,
            rp.secret, rp.resolver, rp.owner);
        
        bytes32 label = keccak256(bytes(rp.name));
        uint256 tokenId = uint256(label);
        bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));
        
        uint256 expires;
        if (rp.resolver != address(0)) {
            expires = base.register(tokenId, address(this), rp.duration);

            base.ens().setResolver(nodehash, rp.resolver);
            IAddrResolver(rp.resolver).setAddr(nodehash, rp.owner);
            
            base.reclaim(tokenId, rp.owner);
            base.transferFrom(address(this), rp.owner, tokenId);
        } else {
            expires = base.register(tokenId, rp.owner, rp.duration);
        }
        
        string memory fullname = rp.name.concat(".").concat(base.baseName());
        nameMap.setBaseInfo(nodehash, fullname, address(base), tokenId);
        
        emit NameRegistered(rp.name, label, rp.owner, cost, expires);

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    function registerAngryCat(
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        uint256 nftId)
        external payable onlyFixedTimes("AngryCat") {
        
        require(!owner.isContract(), "owner can not be contract");
        
        address nftAddress = 0xDCf68c8eBB18Df1419C7DFf17ed33505Faf8A20C;
        require(IERC721Enumerable(nftAddress).ownerOf(nftId) == owner, "is not owner");
        
        require(nftMintCounts[nftAddress][nftId] == 0, "minted");
        nftMintCounts[nftAddress][nftId] = 1;
        
        WTicket.safeTransferFrom(msg.sender, address(this), 0, WTicketPrices[4], "");
        
        bytes memory name = bytes("0000");
        for (uint256 i = 4; i > 0; --i) {
            name[i - 1] = bytes1(uint8(nftId % 10 + 48));
            nftId /= 10;
        }
        
        _register(RegistrarParams({
            name: string(name),
            numberMin: type(uint256).max,
            owner: owner,
            duration: duration,
            secret: secret,
            resolver: resolver
        }));
    }
    
    function registerOG(
        string calldata name,
        uint256 duration,
        bytes32 secret,
        address resolver,
        uint256 id,
        uint256 size,
        uint8 v, bytes32 r, bytes32 s)
        external payable onlyFixedTimes("OG") {
        
        require(name.utf8length() >= size, "size too long");
        
        bytes memory message = abi.encodePacked(
            block.chainid, msg.sender, uint256(1), id, size);
        signCheck.requireSignature(message, v, r, s);
        
        require(!ogUseds[id], "minted");
        ogUseds[id] = true;
        
        _register(RegistrarParams({
            name: name,
            numberMin: 5,
            owner: msg.sender,
            duration: duration,
            secret: secret,
            resolver: resolver
        }));
    }
    
    function registerWTicket(
        string calldata name,
        uint256 duration,
        bytes32 secret,
        address resolver)
        external payable onlyFixedTimes("WTicket") {
        
        uint256 length = name.utf8length();
        if (length >= WTicketPrices.length) {
            length = WTicketPrices.length - 1;
        }
        uint256 price = WTicketPrices[length];
        
        WTicket.safeTransferFrom(msg.sender, address(this), 0, price, "");
        
        _register(RegistrarParams({
            name: name,
            numberMin: 5,
            owner: msg.sender,
            duration: duration,
            secret: secret,
            resolver: resolver
        }));
    }
    
    function renew(string calldata name, uint256 duration)
        external payable onlyFixedTimes("renew") {
        
        uint256 cost = priceOracle.price(name, duration);
        require(msg.value >= cost, "value not enough");
        
        bytes32 label = keccak256(bytes(name));
        uint256 expires = base.renew(uint256(label), duration);
        
        emit NameRenewed(name, label, cost, expires);

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    function _consumeCommitment(string memory name, address owner, uint256 duration,
        bytes32 secret, address resolver, address addr)
        internal returns(uint256) {
        
        bytes32 commitment = makeCommitmentWithConfig(name, owner, secret, resolver, addr);
        
        require(commitments[commitment] + minCommitmentAge <= block.timestamp,
            "too young");

        require(commitments[commitment] + maxCommitmentAge > block.timestamp,
            "too old");
        require(available(name), "not available");

        delete(commitments[commitment]);

        require(duration >= MINT_FREE_DURATION, "duration too short");
        uint256 cost = priceOracle.price(name, duration - MINT_FREE_DURATION);
        require(msg.value >= cost, "value not enough");

        return cost;
    }
    
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }
    
    function withdrawWTicket(address to, uint256 amount) external onlyOwner {
        WTicket.safeTransferFrom(address(this), to, 0, amount, "");
    }
    
    function getNFTWhiteLists(address owner, address[] calldata nftAddresses)
        external view returns(NFTWhiteList[] memory) {
        
        uint256 length = nftAddresses.length;
        NFTWhiteList[] memory result = new NFTWhiteList[](length);
        
        for (uint256 i = 0; i < length; ++i) {
            address nftAddress = nftAddresses[i];
            IERC721Enumerable erc721 = IERC721Enumerable(nftAddress);
            uint256 balance = erc721.balanceOf(owner);
            
            NFTWhiteList memory rst = NFTWhiteList({
                nft: nftAddress,
                tokenIds: new uint256[](balance),
                mintCounts: new uint256[](balance)
            });
            
            for (uint256 j = 0; j < balance; ++j) {
                uint256 tokenId = erc721.tokenOfOwnerByIndex(owner, j);
                rst.tokenIds[j] = tokenId;
                rst.mintCounts[j] = nftMintCounts[nftAddress][tokenId];
            }
            
            result[i] = rst;
        }
        
        return result;
    }
    
    function getOGUsed(uint256[] calldata ids)
        external view returns(bool[] memory) {
        
        uint256 length = ids.length;
        bool[] memory result = new bool[](length);
        
        for (uint256 i = 0; i < length; ++i) {
            result[i] = ogUseds[ids[i]];
        }
        
        return result;
    }
    
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override pure returns(bytes4) {
        
        return IERC1155Receiver.onERC1155Received.selector;
    }
    
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override pure returns(bytes4) {
        
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
    
    function supportsInterface(bytes4)
        external override pure returns(bool) {
        
        return false;
    }
}