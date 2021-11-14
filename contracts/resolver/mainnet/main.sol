//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";
import { Helper } from "./helpers.sol";

import { 
    InstaFlashloanAggregatorInterface
} from "./interfaces.sol";

contract FlashResolver is Helper {
    using SafeERC20 for IERC20;

    function getBestRoutes(address[] memory _tokens, uint256[] memory _amounts) public view returns (uint8[] memory, uint256) {
        uint8[] memory bRoutes_;
        uint256 feeBPS_;
        uint8[] memory routes_ = flashloanAggregator.getRoutes();
        uint8[] memory routesWithAvailability_ = getRoutesWithAvailability(routes_, _tokens, _amounts);
        uint8 j = 0;
        bRoutes_ = new uint8[](routes_.length);
        feeBPS_ = type(uint256).max;
        for(uint256 i = 0; i < routesWithAvailability_.length; i++) {
            if(routesWithAvailability_[i] != 0) {
                uint routeFeeBPS_ = flashloanAggregator.calculateFeeBPS(routesWithAvailability_[i]);
                if(feeBPS_ > routeFeeBPS_) {
                    feeBPS_ = routeFeeBPS_;
                    bRoutes_[0] = routesWithAvailability_[i];
                    j=0;
                } else if (feeBPS_ == routeFeeBPS_) {
                    j++;
                    bRoutes_[j] = routesWithAvailability_[i];
                }
            } 
        }
        uint8[] memory bestRoutes_ = new uint8[](j);
        for(uint256 i = 0; i < j ; i++) {
            bestRoutes_[i] = bRoutes_[i];
        }
        return (bestRoutes_, feeBPS_);
    }
    
}

contract InstaFlashloanResolver is FlashResolver {
    using SafeERC20 for IERC20;

    constructor(address _flashloanAggregatorAddr) {
        flashloanAggregator = InstaFlashloanAggregatorInterface(_flashloanAggregatorAddr);
    }

    receive() external payable {}

}
