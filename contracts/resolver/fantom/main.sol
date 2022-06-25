//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Helper} from "./helpers.sol";
import {InstaFlashloanAggregatorInterface} from "./interfaces.sol";

contract AdminModule is Helper {
    event updateOwnerLog(address indexed oldOwner, address indexed newOwner);

    /**
     * @dev owner gaurd.
     * @notice owner gaurd.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "not-owner");
        _;
    }

    /**
     * @dev Update owner.
     * @notice Update owner.
     * @param newOwner_ address of new owner.
     */
    function updateOwner(address newOwner_) external onlyOwner {
        address oldOwner_ = owner;
        owner = newOwner_;
        emit updateOwnerLog(oldOwner_, newOwner_);
    }

    /**
     * @dev Function to add new routes.
     * @notice Function to add new routes and implementations.
     * @param _routes routes to add.
     * @param _resolverImpls implementations of their respective routes.
     */
    function addNewRoutes(
        uint256[] memory _routes,
        address[] memory _resolverImpls
    ) public onlyOwner {
        require(_routes.length == _resolverImpls.length, "lengths-dont-match");
        uint256 length = _routes.length;
        for (uint256 i = 0; i < length; i++) {
            require(
                routeToResolver[_routes[i]] == address(0),
                "route-already-added"
            );
            routeToResolver[_routes[i]] = _resolverImpls[i];
        }
    }

    /**
     * @dev Function to update existing routes.
     * @notice Function to update existing routes and implementations.
     * @param _routes routes to update.
     * @param _resolverImpls implementations of their respective routes.
     */
    function updateResolverImplementations(
        uint256[] memory _routes,
        address[] memory _resolverImpls
    ) public onlyOwner {
        require(_routes.length == _resolverImpls.length, "lengths-dont-match");
        uint256 length = _routes.length;
        for (uint256 i = 0; i < length; i++) {
            routeToResolver[_routes[i]] = _resolverImpls[i];
        }
    }
}

contract FlashResolverFantom is Helper {
    function getRoutesInfo()
        public
        view
        returns (uint16[] memory routes_, uint256[] memory fees_)
    {
        routes_ = flashloanAggregator.getEnabledRoutes();
        fees_ = new uint256[](routes_.length);
        for (uint256 i = 0; i < routes_.length; i++) {
            fees_[i] = flashloanAggregator.calculateFeeBPS(uint256(routes_[i]));
        }
    }

    function getBestRoutes(address[] memory _tokens, uint256[] memory _amounts)
        public
        view
        returns (uint16[] memory, uint256)
    {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        uint16[] memory bRoutes_;
        uint256 feeBPS_;
        uint16[] memory routes_ = flashloanAggregator.getEnabledRoutes();
        uint16[] memory routesWithAvailability_ = getRoutesWithAvailability(
            _tokens,
            _amounts
        );
        uint16 j = 0;
        bRoutes_ = new uint16[](routes_.length);
        feeBPS_ = type(uint256).max;
        for (uint256 i = 0; i < routesWithAvailability_.length; i++) {
            if (routesWithAvailability_[i] != 0) {
                uint256 routeFeeBPS_ = flashloanAggregator.calculateFeeBPS(
                    uint256(routesWithAvailability_[i])
                );
                if (feeBPS_ > routeFeeBPS_) {
                    feeBPS_ = routeFeeBPS_;
                    bRoutes_[0] = routesWithAvailability_[i];
                    j = 1;
                } else if (feeBPS_ == routeFeeBPS_) {
                    bRoutes_[j] = routesWithAvailability_[i];
                    j++;
                }
            }
        }
        uint16[] memory bestRoutes_ = new uint16[](j);
        for (uint256 i = 0; i < j; i++) {
            bestRoutes_[i] = bRoutes_[i];
        }
        return (bestRoutes_, feeBPS_);
    }

    function getData(address[] memory _tokens, uint256[] memory _amounts)
        public
        view
        returns (
            uint16[] memory routes_,
            uint256[] memory fees_,
            uint16[] memory bestRoutes_,
            uint256 bestFee_
        )
    {
        (routes_, fees_) = getRoutesInfo();
        (bestRoutes_, bestFee_) = getBestRoutes(_tokens, _amounts);
        return (routes_, fees_, bestRoutes_, bestFee_);
    }
}

contract InstaFlashloanResolverFantom is FlashResolverFantom {
    // function initialize(address aggregator, uint256[] memory _routes, address[] memory impls) public {
    //     flashloanAggregatorAddr = aggregator;
    //     uint256 length = _routes.length;
    //     for(uint i = 0; i < length; i++) {
    //         routeToResolver[_routes[i]] =  impls[i];
    //     }
    // }
    receive() external payable {}
}
