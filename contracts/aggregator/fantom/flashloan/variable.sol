//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../../../common/variables.sol";

contract ConstantVariables {
    address public constant treasuryAddr =
        0x6C4061A00F8739d528b185CC683B6400E0cd396a;
    ListInterface public constant instaList = ListInterface(0x10e166c3FAF887D8a61dE6c25039231eE694E926);
}

contract Variables is ConstantVariables {

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

    address public owner;
}
