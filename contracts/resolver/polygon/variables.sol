//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    address public constant aaveLendingAddr =
        0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);
    IAaveV3DataProvider public constant aaveV3DataProvider =
        IAaveV3DataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    address public constant balancerLendingAddr =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    address private flashloanAggregatorAddr =
        0xB2A7F20D10A006B0bEA86Ce42F2524Fde5D6a0F4;
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);

    address public constant wethAddr =
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant usdcAddr =
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant wmaticAddr =
        0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
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
