//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    address public constant aaveLendingAddr =
        0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    address public constant aaveProtocolDataProviderAddr =
        0x65285E9dfab318f57051ab2b139ccCf232945451;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(aaveProtocolDataProviderAddr);
    IAaveV3DataProvider public constant aaveV3DataProvider =
        IAaveV3DataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    address private flashloanAggregatorAddr =
        0xC9309FD3e1928e1535740be35A1A58C9E333876f;
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
}
