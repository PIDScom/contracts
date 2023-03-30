pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./interface/IPriceOracle.sol";
import "./interface/IPriceToken.sol";

import "./lib/String.sol";

contract StablePriceOracle is Ownable, IPriceOracle {
    using String for string;
    
    IPriceToken priceToken;
    
    uint256[] public prices;
    
    function setPriceToken(address pt) external onlyOwner {
        priceToken = IPriceToken(pt);
    }
    
    function setUnitPrice(uint256[] calldata ps) external onlyOwner {
        prices = ps;
    }
    
    function price(string calldata name, uint256 duration)
        external override view returns(uint256) {
        
        uint256 length = name.utf8length();
        if (length >= prices.length) {
            length = prices.length - 1;
        }
        
        return convert(prices[length] * duration);
    }
    
    function unitPrice(string calldata name, uint256 duration)
        external override view returns(uint256) {
        
        duration;
        
        uint256 length = name.utf8length();
        if (length >= prices.length) {
            length = prices.length - 1;
        }
        
        return prices[length];
    }
    
    function convert(uint256 amount) public override view returns(uint256) {
        // decimal of priceToken is 18
        return amount * 1e18 / uint256(priceToken.read());
    }
}