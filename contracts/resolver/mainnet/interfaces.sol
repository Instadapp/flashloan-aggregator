//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface InstaFlashloanAggregatorInterface {
    function getRoutes() external pure returns (uint8[] memory);
    function calculateFeeBPS(uint256 _route) external view returns (uint256);
    function tokenToCToken(address) external view returns (address);
}

interface IAaveProtocolDataProvider {
    function getReserveConfigurationData(address asset) external view returns (uint256, uint256, uint256, uint256, uint256, bool, bool, bool, bool, bool);
}    

interface IBalancerWeightedPoolFactory {
    function isPoolFromFactory(address pool) external view returns (bool);
}

interface IBalancerWeightedPool2TokensFactory {
    function isPoolFromFactory(address pool) external view returns (bool);
}

interface IBalancerStablePoolFactory {
    function isPoolFromFactory(address pool) external view returns (bool);
}

interface IBalancerLiquidityBootstrappingPoolFactory {
    function isPoolFromFactory(address pool) external view returns (bool);
}

interface IBalancerMetaStablePoolFactory {
    function isPoolFromFactory(address pool) external view returns (bool);
}

interface IBalancerInvestmentPoolFactory {
    function isPoolFromFactory(address pool) external view returns (bool);
}