//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    InstaFlashloanAggregatorInterface,
    IAaveProtocolDataProvider
} from "./interfaces.sol";

contract Variables {

    // IndexInterface public constant instaIndex = IndexInterface(address(0)); // TODO: update at the time of deployment
    // ListInterface public immutable instaList = ListInterface(address(0)); // TODO: update at the time of deployment

    // address public immutable wchainToken = address(0); // TODO: update at the time of deployment
    address public constant chainToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // TokenInterface public wchainContract = TokenInterface(wchainToken);

    address public constant aaveLendingAddr = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address public constant aaveProtocolDataProviderAddr = 0x7551b5D2763519d4e37e8B81929D336De671d46d;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider = IAaveProtocolDataProvider(aaveProtocolDataProviderAddr);

    address public constant balancerLendingAddr = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    InstaFlashloanAggregatorInterface internal flashloanAggregator;

}