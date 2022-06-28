//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Structs {
    struct FlashloanVariables {
        address[] _tokens;
        uint256[] _amounts;
        uint256[] _iniBals;
        uint256[] _finBals;
        uint256[] _instaFees;
    }
}
