//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {InstaFlashloanAggregatorInterface, IAaveProtocolDataProvider} from "./interfaces.sol";

contract Variables {
    address public constant aaveLendingAddr =
        0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    address public constant aaveProtocolDataProviderAddr =
        0x65285E9dfab318f57051ab2b139ccCf232945451;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(aaveProtocolDataProviderAddr);

    address private flashloanAggregatorAddr =
        0x2b65731A085B55DBe6c7DcC8D717Ac36c00F6d19;
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
}
