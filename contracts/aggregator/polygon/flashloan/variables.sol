//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    IndexInterface,
    ListInterface,
    IAaveLending,
    IBalancerLending,
    IInteropLending
} from "./interfaces.sol";

contract ConstantVariables {


    address public constant aaveLendingAddr = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    IAaveLending public constant aaveLending = IAaveLending(aaveLendingAddr);

    address public constant balancerLendingAddr = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    IBalancerLending public constant balancerLending = IBalancerLending(balancerLendingAddr);

    address public constant interopLendingAddr = 0x6aB2f727Ef3Df85Cf6bCeF517a411610aBf3c9A4;
    IInteropLending public constant interopLending = IInteropLending(interopLendingAddr);

    address public constant wEthToken = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    uint256 public constant wethBorrowAmountPercentage = 80;

    address public constant treasuryAddr = 0x6e9d36eaeC63Bc3aD4A47fb0d7826A9922AAfC22;
    address private constant instaListAddr = 0x839c2D3aDe63DF5b0b8F3E57D5e145057Ab41556;
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

}