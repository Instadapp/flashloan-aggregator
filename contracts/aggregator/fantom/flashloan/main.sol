//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import './helper.sol';
import '../../common/main.sol';

/**
 * @title Flashloan.
 * @dev Flashloan aggregator for Fantom.
 */

contract FlashAggregatorFantom is FlashAggregator {
    event LogFlashloan(address indexed account, uint256 indexed route, address[] tokens, uint256[] amounts);

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
        require(_tokens.length == _amounts.length, 'array-lengths-not-same');
        require(routeStatus[_route] == true, 'route-disabled');

        implToCall = routeToImpl[_route];

        Address.functionDelegateCall(implToCall, msg.data, 'call-to-impl-failed');

        delete implToCall;
        emit LogFlashloan(msg.sender, _route, _tokens, _amounts);
    }
}

contract InstaFlashAggregatorFantom is FlashAggregatorFantom {
    function initialize(address owner_, address aave_, address fla_) public {
        require(status == 0, 'cannot-call-again');
        require(ownerStatus == 0, 'only-once');
        owner = owner_;
        ownerStatus = 1;
        status = 1;
        routeToImpl[9] = aave_;
        routeStatus[9] = true;
        routes.push(9);
        routeToImpl[10] = fla_;
        routeStatus[10] = true;
        routes.push(10);
    }

    // Fallback function
    fallback(bytes calldata input) external payable returns (bytes memory output) {
        output = Address.functionDelegateCall(implToCall, input, 'fallback-impl-call-failed');
    }

    receive() external payable {}
}
