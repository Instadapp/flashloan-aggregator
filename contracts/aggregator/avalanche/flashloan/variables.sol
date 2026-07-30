//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract ConstantVariables {

    address public constant aaveV2LendingAddr = 0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    IAaveV2Lending public constant aaveV2Lending = IAaveV2Lending(aaveV2LendingAddr);

    address public constant aaveV3LendingAddr = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    IAaveV3Lending public constant aaveV3Lending = IAaveV3Lending(aaveV3LendingAddr);

    address public constant treasuryAddr = 0x4AdA59A08A68ED7549279eE647FB95922D15C4CF;

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

}