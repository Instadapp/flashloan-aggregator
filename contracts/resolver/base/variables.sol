//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    IAaveV3DataProvider public constant aaveV3DataProvider =
        IAaveV3DataProvider(0x2d8A3C5677189723C4cB8873CfC9C8976FDF38Ac);

    address private flashloanAggregatorAddr =
        0xA18519a6bb1282954e933DA0A775924E4CcE6019;
    
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
    
    address public constant wethAddr = 0x4200000000000000000000000000000000000006;
    address public constant usdbcAddr = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
   
    address public constant uniswapFactoryAddr = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}
