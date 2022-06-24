//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface InstaFlashloanAggregatorInterface {
    function getRoutes() external pure returns (uint16[] memory);

    function getEnabledRoutes() external view returns (uint256[] memory routes_, bool[] memory routesBool_);

    function calculateFeeBPS(uint256 _route) external view returns (uint256);
}
