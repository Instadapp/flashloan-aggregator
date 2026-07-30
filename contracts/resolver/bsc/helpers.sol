//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./variables.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helper is Variables {

    function getAaveV3Availability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        uint length = _tokens.length;
        for (uint256 i = 0; i < length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            (, , , , , , , , bool isActive, ) = aaveV3DataProvider
                .getReserveConfigurationData(_tokens[i]);
            (address aTokenAddr, , ) = aaveV3DataProvider
                .getReserveTokensAddresses(_tokens[i]);
            if (isActive == false) return false;
            if (token_.balanceOf(aTokenAddr) < _amounts[i]) return false;
        }
        return true;
    }

    function getRoutesWithAvailability(
        uint16[] memory _routes,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (uint16[] memory) {
        uint16[] memory routesWithAvailability_ = new uint16[](_routes.length);
        uint256 j = 0;
        for (uint256 i = 0; i < _routes.length; i++) {
            if (_routes[i] == 12) {
                if (_tokens.length == 1 || _tokens.length == 2) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 9) {
                if (getAaveV3Availability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            }
        }
        return routesWithAvailability_;
    }

    function bubbleSort(address[] memory _tokens, uint256[] memory _amounts)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            for (uint256 j = 0; j < _tokens.length - i - 1; j++) {
                if (_tokens[j] > _tokens[j + 1]) {
                    (
                        _tokens[j],
                        _tokens[j + 1],
                        _amounts[j],
                        _amounts[j + 1]
                    ) = (
                        _tokens[j + 1],
                        _tokens[j],
                        _amounts[j + 1],
                        _amounts[j]
                    );
                }
            }
        }
        return (_tokens, _amounts);
    }

    function validateTokens(address[] memory _tokens) internal pure {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            require(_tokens[i] != _tokens[i + 1], "non-unique-tokens");
        }
    }

    function computeAddress(address factory, address token0, address token1)
        internal
        view
        returns (address pair)
    {
        IPancakeFactory pancakeFactory = IPancakeFactory(factory);
        pair = pancakeFactory.getPair(token0, token1); 
    }

    function getPancakeBestPair(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (address) {
        if (_tokens.length == 1) {
            address[] memory checkTokens_ = new address[](2);
            checkTokens_[0] = usdtAddr;
            checkTokens_[1] = wbnbAddr;

            address bestPair;
            for (uint256 i = 0; i < checkTokens_.length; i++) {
                if (_tokens[0] == checkTokens_[i]) {
                    break;
                }
                address bestPairToken0;
                address bestPairToken1;
                if (_tokens[0] < checkTokens_[i]) {
                    bestPairToken0 = _tokens[0];
                    bestPairToken1 = checkTokens_[i];
                } else {
                    bestPairToken0 = checkTokens_[i];
                    bestPairToken1 = _tokens[0];
                }
                bestPair = computeAddress(pancakeFactoryAddr, bestPairToken0, bestPairToken1);

                if (bestPair != address(0)) {
                    uint256 balance0 = IERC20(bestPairToken0).balanceOf(
                        bestPair
                    );
                    uint256 balance1 = IERC20(bestPairToken1).balanceOf(
                        bestPair
                    );
                    if (_tokens[0] < checkTokens_[i]) {
                        if (balance0 >= _amounts[0]) {
                            return bestPair;
                        }
                    } else {
                        if (balance1 >= _amounts[0]) {
                            return bestPair;
                        }
                    }
                }
                
            }
            return bestPair;
        } else {
            address bestPairToken0 = _tokens[0];
            address bestPairToken1 = _tokens[1];

            address bestPair = computeAddress(pancakeFactoryAddr, bestPairToken0, bestPairToken1);
            if (bestPair != address(0)) {
                uint256 balance0 = IERC20(bestPairToken0).balanceOf(bestPair);
                uint256 balance1 = IERC20(bestPairToken1).balanceOf(bestPair);
                if (balance0 >= _amounts[0] && balance1 >= _amounts[1]) {
                    return bestPair;
                }
            }
            return bestPair;
        }
    }
}
