//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Variables} from "./variables.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool} from "./interfaces.sol";

contract Helper is Variables {
    function getAaveAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            (, , , , , , , , bool isActive, ) = aaveProtocolDataProvider
                .getReserveConfigurationData(_tokens[i]);
            (address aTokenAddr, , ) = aaveProtocolDataProvider
                .getReserveTokensAddresses(_tokens[i]);
            if (isActive == false) return false;
            if (token_.balanceOf(aTokenAddr) < _amounts[i]) return false;
        }
        return true;
    }

    function getBalancerAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            if (token_.balanceOf(balancerLendingAddr) < _amounts[i]) {
                return false;
            }
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
            if (_routes[i] == 1 || _routes[i] == 7) {
                if (getAaveAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 5) {
                if (getBalancerAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 8) {
                if (_tokens.length == 1 || _tokens.length == 2) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else {
                require(false, "invalid-route");
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

    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1, "Token not sorted");
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    function getUniswapBestFee(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal returns (PoolKey memory) {
        if (_tokens.length == 1) {
            PoolKey memory bestKey;

            address[] memory checkTokens_ = new address[](3);
            checkTokens_[0] = USDC;
            checkTokens_[1] = Weth;
            checkTokens_[2] = MATIC;

            uint24[] memory checkFees_ = new uint24[](3);
            checkFees_[0] = 100;
            checkFees_[1] = 500;
            checkFees_[2] = 3000;

            for (uint256 i = 0; i < checkTokens_.length; i++) {
                for (uint256 j = 0; j < checkFees_.length; i++) {
                    if (_tokens[0] == checkTokens_[i]) {
                        break;
                    }
                    bestKey.fee = checkFees_[j];
                    if (_tokens[0] < checkTokens_[i]) {
                        bestKey.token0 = _tokens[0];
                        bestKey.token1 = checkTokens_[i];
                    } else {
                        bestKey.token0 = checkTokens_[i];
                        bestKey.token1 = _tokens[0];
                    }
                    IUniswapV3Pool pool = IUniswapV3Pool(
                        computeAddress(factory, bestKey)
                    );
                    if (_tokens[0] < checkTokens_[i]) {
                        try pool.balance0() {
                            if (pool.balance0() >= _amounts[0]) {
                                return bestKey;
                            }
                        } catch {}
                    } else {
                        try pool.balance1() {
                            if (pool.balance1() >= _amounts[0]) {
                                return bestKey;
                            }
                        } catch {}
                    }
                }
            }
            bestKey.fee = type(uint24).max;
            return bestKey;
        } else {
            PoolKey memory bestKey;
            bestKey.token0 = _tokens[0];
            bestKey.token1 = _tokens[1];

            uint24[] memory checkFees_ = new uint24[](3);
            checkFees_[0] = 100;
            checkFees_[1] = 500;
            checkFees_[2] = 3000;

            for (uint256 i = 0; i < checkFees_.length; i++) {
                bestKey.fee = checkFees_[i];
                IUniswapV3Pool pool = IUniswapV3Pool(
                    computeAddress(factory, bestKey)
                );
                try pool.balance0() {
                    if (
                        pool.balance0() >= _amounts[0] &&
                        pool.balance1() >= _amounts[1]
                    ) {
                        return bestKey;
                    }
                } catch {}
            }
            bestKey.fee = type(uint24).max;
            return bestKey;
        }
    }
}
