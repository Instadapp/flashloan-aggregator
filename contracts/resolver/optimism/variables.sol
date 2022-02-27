//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {InstaFlashloanAggregatorInterface, IUniswapV3Pool} from "./interfaces.sol";

contract Variables {

    address private flashloanAggregatorAddr =
        0x0000000000000000000000000000000000000000;
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
    
    address public constant Weth = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
   // address public constant MATIC = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
    address public constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}
