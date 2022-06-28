//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CommonVariablesV2 {
    mapping(uint256 => address) public routeToImplementation;
    mapping(uint256 => bool) public routeStatus;
    address internal fallbackImplementation;
    uint256[] public routes;
}