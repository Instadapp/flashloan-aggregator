//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    IndexInterface,
    ListInterface,
    IAaveLending,
    IBalancerLending
} from "./interfaces.sol";

contract Variables {

    bytes32 internal dataHash;
    // if 1 then can enter flashlaon, if 2 then callback
    uint internal status = 1;

    // IndexInterface public constant instaIndex = IndexInterface(address(0)); // TODO: update at the time of deployment
    // ListInterface public immutable instaList = ListInterface(address(0)); // TODO: update at the time of deployment

    // address public immutable wchainToken = address(0); // TODO: update at the time of deployment
    // address public constant chainToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // TokenInterface public wchainContract = TokenInterface(wchainToken);

    struct FlashloanVariables {
        address[] _tokens;
        uint256[] _amounts;
    }

    address public constant aaveLendingAddr = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    IAaveLending public constant aaveLending = IAaveLending(aaveLendingAddr);

    address public constant balancerLendingAddr = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    IBalancerLending public constant balancerLending = IBalancerLending(balancerLendingAddr);

    address public constant wEthToken = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    uint256 public constant wethBorrowAmountPercentage = 80;

    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
}