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

    function getMakerAvailability(address[] memory  _tokens, uint256[] memory _amounts) internal pure returns (bool) {
        uint256 amountsSum_ = 0;
        for(uint256 i = 0; i < _tokens.length; i++) {
            if(_tokens[i] == daiToken) {
                amountsSum_ += _amounts[i];
            } else {
                return false;
            }
        }
        if(amountsSum_ <= daiBorrowAmount) {
            return true;
        } else {
            return false;
        }
    }

    function getCompoundAvailability(address[] memory _tokens, uint256[] memory _amounts) internal view returns (bool) {
        for(uint256 i = 0; i < _tokens.length; i++) {
            if(_tokens[i] == chainToken) {
                if(cEthToken.balance < _amounts[i]) return false;
            } else {
                address cTokenAddr_ = flashloanAggregator.tokenToCToken(_tokens[i]);
                IERC20 token_ = IERC20(_tokens[i]);
                if(cTokenAddr_ == address(0)) return false;
                if(token_.balanceOf(cTokenAddr_) < _amounts[i]) return false;
            }
        }
        return true;
    }

    function getBalancerAvailability(address[] memory _tokens, uint256[] memory _amounts) internal view returns (bool) {
        for(uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            if (token_.balanceOf(balancerLendingAddr) < _amounts[i]) {
                return false;
            }
            // console.log("hello");
            // if ((balancerWeightedPoolFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerWeightedPool2TokensFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerStablePoolFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerLiquidityBootstrappingPoolFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerMetaStablePoolFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerInvestmentPoolFactory.isPoolFromFactory(_tokens[i])
            //     ) == false) {
            //     return false;
            // }
        }
        return true;
    }

    function getRoutesWithAvailability(uint16[] memory _routes, address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint16[] memory) {
        uint16[] memory routesWithAvailability_ = new uint16[](7);
        uint j = 0;
        for(uint256 i = 0; i < _routes.length; i++) {
            if (_routes[i] == 1 || _routes[i] == 4 || _routes[i] == 7) {
                if(getAaveAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 2) {
                if(getMakerAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 3 || _routes[i] == 6) {
                if(getCompoundAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 5) {
                if(getBalancerAvailability(_tokens, _amounts)) {
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