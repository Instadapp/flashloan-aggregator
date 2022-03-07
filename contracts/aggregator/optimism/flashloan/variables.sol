//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IndexInterface, ListInterface, IUniswapV3Pool} from "./interfaces.sol";

contract ConstantVariables {
    address public constant treasuryAddr =
        0x0000000000000000000000000000000000000000;
    address private constant instaListAddr =
        0x9926955e0Dd681Dc303370C52f4Ad0a4dd061687;
    ListInterface public constant instaList = ListInterface(instaListAddr);

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
    address public constant uniswapFactoryAddr =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
}

contract Variables is ConstantVariables {
    bytes32 internal dataHash;
    // if 1 then can enter flashlaon, if 2 then callback
    uint256 internal status;

    struct FlashloanVariables {
        address[] _tokens;
        uint256[] _amounts;
        uint256[] _iniBals;
        uint256[] _finBals;
        uint256[] _instaFees;
    }

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}
