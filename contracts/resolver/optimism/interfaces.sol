//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface InstaFlashloanAggregatorInterface {
    function getRoutes() external pure returns (uint16[] memory);

    function calculateFeeBPS(uint256 _route) external view returns (uint256);

    function tokenToCToken(address) external view returns (address);

    function InstaFeeBPS() external view returns (uint256);
}

interface IUniswapV3Pool {
    /// @dev Get the pool's balance of token0
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance0() external returns (uint256);

    /// @dev Get the pool's balance of token1
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance1() external returns (uint256);
}
