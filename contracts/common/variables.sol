//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces.sol";

contract VariablesCommon {
    mapping(uint256 => address) public routeToImplementation;
    mapping(uint256 => bool) public routeStatus;
    address internal fallbackImplementation;
    uint256[] public routes;
    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
}
