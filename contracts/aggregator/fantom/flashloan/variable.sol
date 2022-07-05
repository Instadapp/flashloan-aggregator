//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../common/interfaces.sol";
import "../../../common/variablesV1.sol";
import "../../../common/variablesV2.sol";
import "../../../common/structs.sol";

contract ConstantVariables {
    address public constant treasuryAddr =
        0x6C4061A00F8739d528b185CC683B6400E0cd396a;
    ListInterface public constant instaList = ListInterface(0x10e166c3FAF887D8a61dE6c25039231eE694E926);
    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
}

contract FantomVariablesV1 {
    address public owner;

    /**
     * @dev owner gaurd.
     * @notice owner gaurd.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "not-owner");
        _;
    }
}

contract Variables is ConstantVariables, CommonVariablesV1, Structs, FantomVariablesV1, CommonVariablesV2 {
    // ******** Stroage Variable layout ******* //

    /* CommonVariablesV1
        // bytes32 internal dataHash;
        // uint256 internal status;
    */

    /* Structs
        FlashloanVariables;
    */

    /* FantomVariablesV1
        // address public owner;
    */

    /* CommonVariablesV2
        // mapping(uint256 => address) public routeToImplementation;
        // mapping(uint256 => bool) public routeStatus;
        // address internal fallbackImplementation;
        // uint256[] public routes;
    */
}