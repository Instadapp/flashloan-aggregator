//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    IAaveV3DataProvider public constant aaveV3DataProvider =
        IAaveV3DataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    address private flashloanAggregatorAddr =
        0x84E6b05A089d5677A702cF61dc14335b4bE5b282;
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
    
    address public constant wethAddr = 0x4200000000000000000000000000000000000006;
    address public constant usdcAddr = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
   
    address public constant uniswapFactoryAddr = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}
