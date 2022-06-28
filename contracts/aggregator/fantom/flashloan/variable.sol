//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../common/interfaces.sol";
import "../../../common/variablesV1.sol";
import "../../../common/variablesV2.sol";
import "../../../common/structs.sol";

contract ConstantVariables {
    address public constant treasuryAddr =
        0x6C4061A00F8739d528b185CC683B6400E0cd396a;
    address private constant instaListAddr =
        0x10e166c3FAF887D8a61dE6c25039231eE694E926;
    ListInterface public constant instaList = ListInterface(instaListAddr);
    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
}

contract FantonVariablesV1 {
    address public owner;
}

contract Variables is ConstantVariables, Structs, CommonVariablesV1, FantonVariablesV1, CommonVariablesV2 {
    // ******** Stroage Variable layout ******* //

    /* CommonVariablesV1
        // bytes32 internal dataHash;
        // uint256 internal status;
    */

    /* FantonVariablesV1
        // address public owner;
    */

    /* CommonVariablesV2
        // mapping(uint256 => address) public routeToImplementation;
        // mapping(uint256 => bool) public routeStatus;
        // address internal fallbackImplementation;
        // uint256[] public routes;
    */
}