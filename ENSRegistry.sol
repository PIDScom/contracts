pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "./interface/IENS.sol";

/**
 * The ENS registry contract.
 */
contract ENSRegistry is IENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
        uint256 index;
    }

    mapping(bytes32 => Record) records;
    mapping(address => mapping(address => bool)) operators;
    
    mapping(address => bytes32[]) ownerNodes;
    
    // Permits modifications only by the owner of the specified node.
    modifier authorised(bytes32 node) {
        address _owner = records[node].owner;
        require(_owner == msg.sender || operators[_owner][msg.sender],
            "not authorised");
        _;
    }

    /**
     * @dev Constructs a new ENS registrar.
     */
    constructor() {
        records[0].owner = msg.sender;
        
    }

    /**
     * @dev Sets the record for a node.
     * @param node The node to update.
     * @param _owner The address of the new owner.
     * @param _resolver The address of the resolver.
     * @param _ttl The TTL in seconds.
     */
    function setRecord(bytes32 node, address _owner, address _resolver, uint64 _ttl)
        external override {
        
        setOwner(node, _owner);
        _setResolverAndTTL(node, _resolver, _ttl);
    }

    /**
     * @dev Sets the record for a subnode.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param _owner The address of the new owner.
     * @param _resolver The address of the resolver.
     * @param _ttl The TTL in seconds.
     */
    function setSubnodeRecord(bytes32 node, bytes32 label,
        address _owner, address _resolver, uint64 _ttl)
        external override {
    
        bytes32 subnode = setSubnodeOwner(node, label, _owner);
        _setResolverAndTTL(subnode, _resolver, _ttl);
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node The node to transfer ownership of.
     * @param _owner The address of the new owner.
     */
    function setOwner(bytes32 node, address _owner)
        public override authorised(node) {
        
        _setOwner(node, _owner);
        emit Transfer(node, _owner);
    }

    /**
     * @dev Transfers ownership of a subnode keccak256(node, label) to a new address. May only be called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param _owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 node, bytes32 label, address _owner)
        public override authorised(node) returns(bytes32) {
        
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        _setOwner(subnode, _owner);
        emit NewOwner(node, label, _owner);
        return subnode;
    }

    /**
     * @dev Sets the resolver address for the specified node.
     * @param node The node to update.
     * @param _resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address _resolver)
        public override authorised(node) {
        
        emit NewResolver(node, _resolver);
        records[node].resolver = _resolver;
    }

    /**
     * @dev Sets the TTL for the specified node.
     * @param node The node to update.
     * @param _ttl The TTL in seconds.
     */
    function setTTL(bytes32 node, uint64 _ttl) public override authorised(node) {
        emit NewTTL(node, _ttl);
        records[node].ttl = _ttl;
    }

    /**
     * @dev Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s ENS records. Emits the ApprovalForAll event.
     * @param operator Address to add to the set of authorized operators.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved)
        external override {
        
        operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node The specified node.
     * @return address of the owner.
     */
    function owner(bytes32 node) public override view returns(address) {
        address addr = records[node].owner;
        if (addr == address(this)) {
            return address(0);
        }

        return addr;
    }

    function isOwnerOrApproval(address operator, bytes32 node)
        external override view returns(bool) {
        
        address _owner = records[node].owner;
        return _owner == operator || operators[_owner][operator];
    }

    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param node The specified node.
     * @return address of the resolver.
     */
    function resolver(bytes32 node) public override view returns(address) {
        return records[node].resolver;
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param node The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 node) public override view returns(uint64) {
        return records[node].ttl;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param node The specified node.
     * @return Bool if record exists
     */
    function recordExists(bytes32 node) public override view returns(bool) {
        return records[node].owner != address(0);
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param _owner The address that owns the records.
     * @param operator The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAll(address _owner, address operator)
        external override view returns(bool) {
        
        return operators[_owner][operator];
    }

    function _setOwner(bytes32 node, address _owner) internal {
        if (_owner == address(0)) {
            _owner = address(this);
        }
        
        bytes32[] storage nodes;
        
        Record storage record = records[node];
        if (record.owner != address(0)) {
            nodes = ownerNodes[record.owner];
            nodes[record.index] = nodes[nodes.length - 1];
            nodes.pop();
        }
        
        nodes = ownerNodes[_owner];
        
        record.owner = _owner;
        record.index = nodes.length;
        nodes.push(node);
    }

    function _setResolverAndTTL(bytes32 node, address _resolver, uint64 _ttl) internal {
        if(_resolver != records[node].resolver) {
            records[node].resolver = _resolver;
            emit NewResolver(node, _resolver);
        }

        if(_ttl != records[node].ttl) {
            records[node].ttl = _ttl;
            emit NewTTL(node, _ttl);
        }
    }
    
    function getNodesOfOwner(address user)
        external view returns(bytes32[] memory) {
        
        return ownerNodes[user];
    }
}