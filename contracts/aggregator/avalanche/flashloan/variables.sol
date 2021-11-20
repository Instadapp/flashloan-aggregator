//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    IndexInterface,
    ListInterface,
    IAaveLending
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

    address public constant aaveLendingAddr = 0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    IAaveLending public constant aaveLending = IAaveLending(aaveLendingAddr);

    address public constant treasuryAddr = address(0); // TODO: need to update this

    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
}