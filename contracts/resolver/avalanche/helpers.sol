//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import {Variables} from "./variables.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Helper is Variables {
    using SafeERC20 for IERC20;

    // Helpers

    function getAaveAvailability(address[] memory  _tokens, uint256[] memory  _amounts) internal view returns (bool) {
        for(uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            (,,,,,,,,bool isActive,) = aaveProtocolDataProvider.getReserveConfigurationData(_tokens[i]);
            (address aTokenAddr,,) = aaveProtocolDataProvider.getReserveTokensAddresses(_tokens[i]);
            if(isActive == false) return false;
            if(token_.balanceOf(aTokenAddr) < _amounts[i]) return false;
        }
        return true;
    }

    function getRoutesWithAvailability(uint16[] memory _routes, address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint16[] memory) {
        uint16[] memory routesWithAvailability_ = new uint16[](7);
        uint j = 0;
        for(uint256 i = 0; i < _routes.length; i++) {
            if (_routes[i] == 1) {
                if(getAaveAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else {
                require(false, "invalid-route");
            }
        }
        return routesWithAvailability_;
    }
}