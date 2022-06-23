//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import './helper.sol';
import '../../common/main.sol';

/**
 * @title Flashloan.
 * @dev Flashloan aggregator for Fantom.
 */

contract InstaFlashAggregatorFantom is FlashAggregator {
    function initialize(address owner_, address aave_) public {
        require(status == 0, 'cannot-call-again');
        require(ownerStatus == 0, 'only-once');
        owner = owner_;
        ownerStatus = 1;
        status = 1;
        routeToImpl[9] = aave_;
        routeStatus[9] = true;
        routes.push(9);
    }

    // Fallback function
    fallback() external payable {
        output = Address.functionDelegateCall(implToCall, input, 'fallback-impl-call-failed');
    }

    receive() external payable {}
}
