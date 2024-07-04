//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    address public constant chainToken =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public constant aaveLendingAddr =
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address public constant aaveProtocolDataProviderAddr =
        0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(aaveProtocolDataProviderAddr);


    address public constant aaveV3LendingAddr =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant aaveV3ProtocolDataProviderAddr =
        0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3;
    IAavev3ProtocolDataProvider public constant aaveV3ProtocolDataProvider =
        IAavev3ProtocolDataProvider(aaveV3ProtocolDataProviderAddr);

    address public constant sparkLendingAddr =
        0xC13e21B648A5Ee794902342038FF3aDAB66BE987;
    address public constant sparkProtocolDataProviderAddr =
        0xFc21d6d146E6086B8359705C8b28512a983db0cb;
    ISparkProtocolDataProvider public constant sparkProtocolDataProvider =
        ISparkProtocolDataProvider(sparkProtocolDataProviderAddr);

    address public constant balancerLendingAddr =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    address public constant morphoAddr = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

    address public constant daiToken =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 public constant daiBorrowAmount = 500000000000000000000000000;

    address public constant cEthToken =
        0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    address private flashloanAggregatorAddr =
        0x619Ad2D02dBeE6ebA3CDbDA3F98430410e892882;
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);

    address internal constant randomAddr_ = 0xa9061100d29C3C562a2e2421eb035741C1b42137;
}
