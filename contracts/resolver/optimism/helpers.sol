//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Variables} from "./variables.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool} from "./interfaces.sol";

contract Helper is Variables {
    function getRoutesWithAvailability(
        uint16[] memory _routes,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (uint16[] memory) {
        uint16[] memory routesWithAvailability_ = new uint16[](7);
        uint256 j = 0;
        for (uint256 i = 0; i < _routes.length; i++) {
            if (_routes[i] == 8) {
                routesWithAvailability_[j] = _routes[i];
                j++;
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
        uint256 length = _tokens.length;
        if (length == 1) {
            address token0 = _tokens[0];

            PoolKey memory bestKey;
            bestKey.fee = type(uint24).max;

            PoolKey memory key;

            if (token0 != Weth) {
                if (token0 < Weth) {
                    key.token0 = token0;
                    key.token1 = Weth;
                } else {
                    key.token0 = Weth;
                    key.token1 = token0;
                }
                key.fee = 100;
                address uniswapPoolAddress = computeAddress(factory, key);
                IUniswapV3Pool pool1 = IUniswapV3Pool(uniswapPoolAddress);

                if (pool1.balance0() >= _amounts[0]) {
                    if (key.fee < bestKey.fee) bestKey = key;
                }
            }

            if (token0 != Weth) {
                if (token0 < Weth) {
                    key.token0 = token0;
                    key.token1 = Weth;
                } else {
                    key.token0 = Weth;
                    key.token1 = token0;
                }
                key.fee = 500;
                address uniswapPoolAddress = computeAddress(factory, key);
                IUniswapV3Pool pool = IUniswapV3Pool(uniswapPoolAddress);

                if (pool.balance0() >= _amounts[0]) {
                    if (key.fee < bestKey.fee) bestKey = key;
                }
            }

            if (token0 != Weth) {
                if (token0 < Weth) {
                    key.token0 = token0;
                    key.token1 = Weth;
                } else {
                    key.token0 = Weth;
                    key.token1 = token0;
                }
                key.fee = 3000;
                address uniswapPoolAddress = computeAddress(factory, key);
                IUniswapV3Pool pool = IUniswapV3Pool(uniswapPoolAddress);

                if (pool.balance0() >= _amounts[0]) {
                    if (key.fee < bestKey.fee) bestKey = key;
                }
            }

            if (token0 != USDC) {
                if (token0 < USDC) {
                    key.token0 = token0;
                    key.token1 = USDC;
                } else {
                    key.token0 = USDC;
                    key.token1 = token0;
                }
                key.fee = 100;
                address uniswapPoolAddress = computeAddress(factory, key);
                IUniswapV3Pool pool = IUniswapV3Pool(uniswapPoolAddress);

                if (pool.balance0() >= _amounts[0]) {
                    if (key.fee < bestKey.fee) bestKey = key;
                }
            }

            if (token0 != USDC) {
                if (token0 < USDC) {
                    key.token0 = token0;
                    key.token1 = USDC;
                } else {
                    key.token0 = USDC;
                    key.token1 = token0;
                }
                key.fee = 500;
                address uniswapPoolAddress = computeAddress(factory, key);
                IUniswapV3Pool pool = IUniswapV3Pool(uniswapPoolAddress);

                if (pool.balance0() >= _amounts[0]) {
                    if (key.fee < bestKey.fee) bestKey = key;
                }
            }

            if (token0 != USDC) {
                if (token0 < USDC) {
                    key.token0 = token0;
                    key.token1 = USDC;
                } else {
                    key.token0 = USDC;
                    key.token1 = token0;
                }
                key.fee = 3000;
                address uniswapPoolAddress = computeAddress(factory, key);
                IUniswapV3Pool pool = IUniswapV3Pool(uniswapPoolAddress);

                if (pool.balance0() >= _amounts[0]) {
                    if (key.fee < bestKey.fee) bestKey = key;
                }
            }

            return bestKey;
        } else {
            bubbleSort(_tokens, _amounts);
            address token0 = _tokens[0];
            address token1 = _tokens[1];

            PoolKey memory bestKey;
            bestKey.fee = type(uint24).max;

            PoolKey memory key;

            key.token0 = token0;
            key.token1 = token1;
            key.fee = 100;

            address uniswapPoolAddress1 = computeAddress(factory, key);
            IUniswapV3Pool pool1 = IUniswapV3Pool(uniswapPoolAddress1);

            if (
                pool1.balance0() >= _amounts[0] &&
                pool1.balance1() >= _amounts[1]
            ) {
                if (key.fee < bestKey.fee) bestKey = key;
            }

            key.fee = 500;
            address uniswapPoolAddress2 = computeAddress(factory, key);
            IUniswapV3Pool pool2 = IUniswapV3Pool(uniswapPoolAddress2);

            if (
                pool2.balance0() >= _amounts[0] &&
                pool2.balance1() >= _amounts[1]
            ) {
                if (key.fee < bestKey.fee) bestKey = key;
            }

            key.fee = 3000;
            address uniswapPoolAddress3 = computeAddress(factory, key);
            IUniswapV3Pool pool3 = IUniswapV3Pool(uniswapPoolAddress3);

            if (
                pool3.balance0() >= _amounts[0] &&
                pool3.balance1() >= _amounts[1]
            ) {
                if (key.fee < bestKey.fee) bestKey = key;
            }

            return bestKey;
        }
    }
}
