//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";
import "../../common/interface.sol";

contract ConstantVariables {

    address public constant aaveV3LendingAddr = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    IAaveV3Lending public constant aaveV3Lending = IAaveV3Lending(aaveV3LendingAddr);

    address public constant treasuryAddr = 0x6C4061A00F8739d528b185CC683B6400E0cd396a;
    address private constant instaListAddr = 0x10e166c3FAF887D8a61dE6c25039231eE694E926;
    ListInterface public constant instaList = ListInterface(instaListAddr);

    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%

}

contract Variables is ConstantVariables {

    bytes32 internal dataHash;
    // if 1 then can enter flashlaon, if 2 then callback
    uint internal status;

    struct FlashloanVariables {
        address[] _tokens;
        uint256[] _amounts;
        uint256[] _iniBals;
        uint256[] _finBals;
        uint256[] _instaFees;
    }

    address internal AAVE_IMPL;
}
