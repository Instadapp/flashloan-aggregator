//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    IAaveV3DataProvider public constant aaveV3DataProvider =
        IAaveV3DataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    address public constant balancerLendingAddr =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    address private flashloanAggregatorAddr =
        0x1f882522DF99820dF8e586b6df8bAae2b91a782d;
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);

    address public constant wethAddr =
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant usdcAddr =
        0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address public constant uniswapFactoryAddr =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}
