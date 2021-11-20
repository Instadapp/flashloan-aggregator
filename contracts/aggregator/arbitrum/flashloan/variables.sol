//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    IndexInterface,
    ListInterface,
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
        uint256[] _iniBals;
        uint256[] _finBals;
        uint256[] _instaFees;
    }

    address public constant balancerLendingAddr = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    IBalancerLending public constant balancerLending = IBalancerLending(balancerLendingAddr);

    address public constant treasuryAddr = 0xf81AB897E3940E95d749fF2e1F8D38f9b7cBe3cf;
    address public constant instaListAddr = 0x3565F6057b7fFE36984779A507fC87b31EFb0f09;

    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
}