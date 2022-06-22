//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./helpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Flashloan.
 * @dev Flashloan aggregator for Fantom.
 */

contract AdminModule is Helper {
    event updateOwnerLog(address indexed oldOwner, address indexed newOwner);

    event updateWhitelistLog(
        address indexed account,
        bool indexed isWhitelisted_
    );

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
}

contract FlashAggregatorFantom is AdminModule {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );

    event LogCollectRevenue(
        address to,
        address[] tokens,
        uint256[] amounts
    );

    /**
     * @dev Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @notice Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _route route for flashloan.
     * @param _data extra data passed.
    */
    function flashLoan(
        address[] memory _tokens,	
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data,
        bytes calldata // kept for future use by instadapp. Currently not used anywhere.
    ) external {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");
        require(routeStatus[_route] == true, "route-disabled");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);
        
        implToCall = routeToImpl[_route];

        Address.functionDelegateCall(implToCall, msg.data, "call-to-impl-failed");

        emit LogFlashloan(
            msg.sender,
            _route,
            _tokens,
            _amounts
        );
    }

    /**
     * @dev Function to add new routes.
     * @notice Function to add new routes and implementations.
     * @param _routes routes to add.
     * @param _impls implementations of their respective routes.
     */
    function addNewRoutesAndEnable(uint256[] memory _routes, address[] memory _impls) public onlyOwner {
        require(_routes.length == _impls.length, "lengths-dont-match");
        uint length = _routes.length;
        for (uint256 i = 0; i < length; i++) {
            require(routeToImpl[_routes[i]] == address(0), "route-already-exists");
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
    function updateRouteImplementation(uint256[] memory _routes, address[] memory _impls) public onlyOwner {
        require(_routes.length == _impls.length, "lengths-dont-match");
        uint length = _routes.length;
        for (uint256 i = 0; i < length; i++) {
            routeToImpl[_routes[i]] = _impls[i];
        }
    }

    /**
     * @dev Function to change route status.
     * @notice Function to enable and disable routes.
     * @param _routes routes those status we want to change.
     * @param _statuses new statuses.
     */
    function changeRouteStatus(uint256[] memory _routes, bool[] memory _statuses) public onlyOwner {
        require(_routes.length == _statuses.length, "lengths-dont-match");
        uint length = _routes.length;
        for (uint256 i = 0; i < length; i++) {
            routeStatus[_routes[i]] = _statuses[i];
        }
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury. Will be called manually.
     * @param _tokens token addresses for transferring fee to treasury.
     * @param _to treasury address.
     */
    function transferFee(address[] memory _tokens, address _to) public onlyOwner {
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
            if (_amts[i] > 0)
                token_.safeTransfer(_to, _amts[i]);
        }
        emit LogCollectRevenue(_to, _tokens, _amts);
    }

    /**
     * @dev Function to get the list of all routes.
     * @notice Function to get the list of all routes.
    */
    function getRoutes() public view returns (uint256[] memory routes_) {
        uint length = routes.length;
        routes_ = new uint256[](length);
        for(uint i = 0; i < length; i++) {
            routes_[i] = routes[i];
        }
    }

    /**
     * @dev Function to get the list of enabled routes.
     * @notice Function to get the list of enabled routes.
    */
    function getEnabledRoutes() public view returns (uint256[] memory routes_, bool[] memory routesBool_) {
        routes_ = getRoutes();
        uint length = routes_.length;
        routesBool_ = new bool[](length);

        for(uint i = 0; i < length; i++) {
            routesBool_[i] = routeStatus[routes_[i]] == true ? true : false;
        }
    }
}

contract InstaFlashAggregatorFantom is FlashAggregatorFantom {

    function initialize(address owner_, address aave_) public {
        require(status == 0, "cannot-call-again");
        require(ownerStatus == 0, "only-once");
        owner = owner_;
        ownerStatus = 1;
        status = 1;
        routeToImpl[9] = aave_;
        routeStatus[9] = true;
        routes.push(9);
    }

    // Fallback function
    fallback(bytes calldata input) external payable returns (bytes memory output) { 
        output = Address.functionDelegateCall(implToCall, input, "fallback-impl-call-failed");
    }

    receive() external payable {}
}
