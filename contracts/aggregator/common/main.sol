//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./helpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Flashloan.
 * @dev Common aggregator implementation for all chains.
 */

contract AdminModule is HelpersCommon {
    using SafeERC20 for IERC20;

    event updateOwnerLog(address indexed oldOwner, address indexed newOwner);

    event updateWhitelistLog(
        address indexed account,
        bool indexed isWhitelisted_
    );

    event LogCollectRevenue(address to, address[] tokens, uint256[] amounts);

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
     * @param _impls implementations of their respective routes.
     */
    function addNewRoutesAndEnable(
        uint256[] memory _routes,
        address[] memory _impls
    ) public onlyOwner {
        require(_routes.length == _impls.length, "lengths-dont-match");
        uint256 length = _routes.length;
        for (uint256 i = 0; i < length; i++) {
            require(
                routeToImpl[_routes[i]] == address(0),
                "route-already-exists"
            );
            routeToImpl[_routes[i]] = _impls[i];
            routeStatus[_routes[i]] = true;
            routes.push(_routes[i]);
        }
    }

    /**
     * @dev Function to update existing routes.
     * @notice Function to update existing routes and implementations.
     * @param _routes routes to update.
     * @param _impls implementations of their respective routes.
     */
    function updateRouteImplementations(
        uint256[] memory _routes,
        address[] memory _impls
    ) public onlyOwner {
        require(_routes.length == _impls.length, "lengths-dont-match");
        uint256 length = _routes.length;
        for (uint256 i = 0; i < length; i++) {
            require(
                routeToImpl[_routes[i]] != address(0),
                "route-doesnt-exist"
            );
            routeToImpl[_routes[i]] = _impls[i];
        }
    }

    /**
     * @dev Function to change route status.
     * @notice Function to enable and disable routes.
     * @param _routes routes those status we want to change.
     * @param _statuses new statuses.
     */
    function changeRouteStatus(
        uint256[] memory _routes,
        bool[] memory _statuses
    ) public onlyOwner {
        require(_routes.length == _statuses.length, "lengths-dont-match");
        uint256 length = _routes.length;
        for (uint256 i = 0; i < length; i++) {
            routeStatus[_routes[i]] = _statuses[i];
        }
    }

    /**
     * @dev Function to delete route.
     * @notice Function to delete route.
     * @param _route routes to delete.
     */
    function deleteRoute(uint256 _route) public onlyOwner {
        uint256 length = routes.length;
        for (uint256 i = 0; i < length; i++) {
            if (routes[i] == _route) {
                delete routes[i];
                delete routeToImpl[_route];
                delete routeStatus[_route];
            }
        }
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury. Will be called manually.
     * @param _tokens token addresses for transferring fee to treasury.
     * @param _to treasury address.
     */
    function transferFee(address[] memory _tokens, address _to)
        public
        onlyOwner
    {
        uint256[] memory _amts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            uint256 decimals_ = TokenInterface(_tokens[i]).decimals();
            uint256 amtToSub_ = decimals_ == 18 ? 1e10 : decimals_ > 12
                ? 10000
                : decimals_ > 7
                ? 100
                : 10;
            _amts[i] = token_.balanceOf(address(this)) > amtToSub_
                ? (token_.balanceOf(address(this)) - amtToSub_)
                : 0;
            if (_amts[i] > 0) token_.safeTransfer(_to, _amts[i]);
        }
        emit LogCollectRevenue(_to, _tokens, _amts);
    }
}

contract FlashAggregator is AdminModule {
    /**
     * @dev Returns fee for the passed route in BPS.
     * @notice Returns fee for the passed route in BPS. 1 BPS == 0.01%.
     * @param _route route number for flashloan.
     */
    function calculateFeeBPS(uint256 _route)
        public
        view
        returns (uint256 BPS_)
    {
        bytes memory _output = Address.functionStaticCall(
            routeToImpl[_route],
            msg.data,
            "calculateFeeBPS-call-failed"
        );
        BPS_ = abi.decode(_output, (uint256));
    }

    /**
     * @dev Function to get the list of all routes.
     * @notice Function to get the list of all routes.
     */
    function getRoutes() public view returns (uint256[] memory) {
        return routes;
    }

    /**
     * @dev Function to get the list of enabled routes.
     * @notice Function to get the list of enabled routes.
     */
    function getEnabledRoutes()
        public
        view
        returns (uint16[] memory routesEnabled_)
    {
        uint256[] memory routesAll_ = getRoutes();
        uint256 length = routesAll_.length;
        uint256 _count = 0;

        for (uint256 i = 0; i < length; i++) {
            if (routeStatus[routesAll_[i]] == true) {
                _count++;
            }
        }

        routesEnabled_ = new uint16[](_count);
        uint256 k = 0;

        for (uint256 j = 0; j < length; j++) {
            if (routeStatus[routesAll_[j]]) {
                routesEnabled_[k] = uint16(routesAll_[j]);
                k++;
            }
        }
    }
}
