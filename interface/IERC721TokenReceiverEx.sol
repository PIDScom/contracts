pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

interface IERC721TokenReceiverEx {
    function onERC721ExReceived(address operator, address from,
        uint256[] memory tokenIds, bytes memory data)
        external returns(bytes4);
}
