//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    address public constant chainToken =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public constant aaveV3LendingAddr =
        0xBE9Ab38aDe0223570333e083e5b6979A4C63d456;
    address public constant aaveV3ProtocolDataProviderAddr =
        0xECe8c6C27a041A4db0c375C000da7c4A110c4a40;
    IAavev3ProtocolDataProvider public constant aaveV3ProtocolDataProvider =
        IAavev3ProtocolDataProvider(aaveV3ProtocolDataProviderAddr);

    address public constant morphoAddr = 0xd011EE229E7459ba1ddd22631eF7bF528d424A14;

    address private flashloanAggregatorAddr =
        0xa5C8383BeD5F68024419Bf0Ee02C2Fc198B45215; //TODO: change this to deployed flash loan aggregator address
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);

    address public constant wethAddr = 0x036be3D0ABAFD1eB8Ab1fB750944A00Ac2C6dd22;
    address public constant usdcAddr = 0xa947F7E53cbA8323e2eD9308AeFe77289C0B8CaC;

    address internal constant randomAddr_ = 0x78cC562D740f44CCA18AA74126C6dD23F8cFcD38;

    address public constant uniswapFactoryAddr = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c; 
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;


    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}
