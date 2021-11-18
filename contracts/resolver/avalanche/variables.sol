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

    address public constant aaveLendingAddr = 0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    address public constant aaveProtocolDataProviderAddr = 0x65285E9dfab318f57051ab2b139ccCf232945451;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider = IAaveProtocolDataProvider(aaveProtocolDataProviderAddr);

    InstaFlashloanAggregatorInterface internal flashloanAggregator;

}