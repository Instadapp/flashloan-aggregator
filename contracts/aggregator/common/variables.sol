//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import './interfaces.sol';

contract VariablesCommon {
    address public owner;

    bytes32 internal dataHash;
    // if 1 then can enter flashlaon, if 2 then callback
    uint256 internal status;

    struct FlashloanVariables {
        address[] _tokens;
        uint256[] _amounts;
        uint256[] _iniBals;
        uint256[] _finBals;
        uint256[] _instaFees;
    }

    mapping(uint256 => address) public routeToImpl;
    mapping(uint256 => bool) public routeStatus;
    address internal implToCall;
    uint256[] public routes;

    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
}
