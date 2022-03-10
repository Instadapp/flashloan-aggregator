//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface InstaFlashloanAggregatorInterface {
    function getRoutes() external pure returns (uint16[] memory);

    function calculateFeeBPS(uint256 _route) external view returns (uint256);

    function InstaFeeBPS() external view returns (uint256);
}

interface IUniswapV3Pool {
    function balance0() external view returns (uint256);

    function balance1() external view returns (uint256);
}
