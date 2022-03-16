//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";

contract FlashResolverPolygon is Helper {
    function getRoutes() public view returns (uint16[] memory) {
        return flashloanAggregator.getRoutes();
    }

    function getBestRoutes(address[] memory _tokens, uint256[] memory _amounts)
        public
        view
        returns (
            uint16[] memory,
            uint256,
            bytes[] memory
        )
    {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        bytes[] memory _data;

        uint16[] memory bRoutes_;
        uint256 feeBPS_;
        uint16[] memory routes_ = getRoutes();
        uint16[] memory routesWithAvailability_ = getRoutesWithAvailability(
            routes_,
            _tokens,
            _amounts
        );
        uint16 j = 0;
        bRoutes_ = new uint16[](routes_.length);
        _data = new bytes[](routes_.length);
        feeBPS_ = type(uint256).max;
        for (uint256 i = 0; i < routesWithAvailability_.length; i++) {
            if (routesWithAvailability_[i] == 8) {
                PoolKey memory bestKey = getUniswapBestFee(_tokens, _amounts);
                uint256 uniswapFeeBPS_ = uint256(bestKey.fee / 100);
                uint256 instaFeeBps_ = flashloanAggregator.InstaFeeBPS();
                if (uniswapFeeBPS_ < instaFeeBps_) {
                    uniswapFeeBPS_ = instaFeeBps_;
                }
                if (feeBPS_ > uniswapFeeBPS_) {
                    feeBPS_ = uniswapFeeBPS_;
                    bRoutes_[0] = routesWithAvailability_[i];
                    _data[0] = abi.encode(bestKey);
                    j = 1;
                } else if (feeBPS_ == uniswapFeeBPS_) {
                    bRoutes_[j] = routesWithAvailability_[i];
                    _data[j] = abi.encode(bestKey);
                    j++;
                }
            } else if (routesWithAvailability_[i] != 0) {
                uint256 routeFeeBPS_ = flashloanAggregator.calculateFeeBPS(
                    routesWithAvailability_[i]
                );
                if (feeBPS_ > routeFeeBPS_) {
                    feeBPS_ = routeFeeBPS_;
                    bRoutes_[0] = routesWithAvailability_[i];
                    j = 1;
                } else if (feeBPS_ == routeFeeBPS_) {
                    bRoutes_[j] = routesWithAvailability_[i];
                    j++;
                }
            } else {
                break;
            }
        }
        uint16[] memory bestRoutes_ = new uint16[](j);
        bytes[] memory bestData_ = new bytes[](j);
        for (uint256 i = 0; i < j; i++) {
            bestRoutes_[i] = bRoutes_[i];
            bestData_[i] = _data[i];
        }
        return (bestRoutes_, feeBPS_, bestData_);
    }

    function getData(address[] memory _tokens, uint256[] memory _amounts)
        public
        view
        returns (
            uint16[] memory routes_,
            uint16[] memory bestRoutes_,
            uint256 bestFee_,
            bytes[] memory bestData_
        )
    {
        (routes_) = getRoutes();
        (bestRoutes_, bestFee_, bestData_) = getBestRoutes(_tokens, _amounts);
    }
}

contract InstaFlashResolverPolygon is FlashResolverPolygon {
    receive() external payable {}
}
