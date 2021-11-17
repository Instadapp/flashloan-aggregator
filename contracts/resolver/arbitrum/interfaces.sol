//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface InstaFlashloanAggregatorInterface {
    function getRoutes() external pure returns (uint16[] memory);
    function calculateFeeBPS(uint256 _route) external view returns (uint256);
}