// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract InstaFlashPaybackV2Polygon {
    using SafeERC20 for IERC20;

    // Transfers tokens to flashloan aggregator
    function payback(
        address flashloanAggregator_,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external {
        require(
            tokens.length == amounts.length,
            "Tokens and amounts arrays must have the same length"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 amount = amounts[i];

            // Transfer the specified amount of each token from the contract to the flashloan aggregator
            token.safeTransfer(flashloanAggregator_, amount);
        }
    }
}
