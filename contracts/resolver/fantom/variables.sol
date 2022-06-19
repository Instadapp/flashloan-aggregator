//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    IAaveV3DataProvider public constant aaveV3DataProvider =
        IAaveV3DataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    address public flashloanAggregatorAddr =
        0x2b65731A085B55DBe6c7DcC8D717Ac36c00F6d19;//TODO: update
    InstaFlashloanAggregatorInterface public flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
}
