//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    IAaveV3DataProvider public constant aaveV3DataProvider =
        IAaveV3DataProvider(0xf2D6E38B407e31E7E7e4a16E6769728b76c7419F);

    address private flashloanAggregatorAddr =
        0x9ED23816Ed080427B1d2140Eb6E5BC11D2DAe32f;
    
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
    
    address public constant wethAddr = 0x9895D81bB462A195b4922ED7De0e3ACD007c32CB;
    address public constant usdt0Addr = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
   
    address public constant uniswapFactoryAddr = 0xcb2436774C3e191c85056d248EF4260ce5f27A9D; 
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}
