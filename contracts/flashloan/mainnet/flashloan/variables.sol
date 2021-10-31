pragma solidity ^0.8.0;


import { 
    IndexInterface,
    ListInterface,
    TokenInterface,
    IAaveLending
} from "./interfaces.sol";

contract Variables {

    IndexInterface public constant instaIndex = IndexInterface(address(0)); // TODO: update at the time of deployment
    ListInterface public immutable instaList = ListInterface(address(0)); // TODO: update at the time of deployment

    address public immutable wchainToken = address(0); // TODO: update at the time of deployment
    address public constant chainToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    TokenInterface public immutable wchainContract = TokenInterface(wchainToken);

    address public immutable aaveLendingAddr = address(0);
    IAaveLending public immutable aaveLending = IAaveLending(aaveLendingAddr);

}