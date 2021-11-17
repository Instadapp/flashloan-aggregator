//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    InstaFlashloanAggregatorInterface,
    IAaveProtocolDataProvider,
    IBalancerWeightedPoolFactory,
    IBalancerWeightedPool2TokensFactory,
    IBalancerStablePoolFactory,
    IBalancerLiquidityBootstrappingPoolFactory,
    IBalancerMetaStablePoolFactory,
    IBalancerInvestmentPoolFactory
} from "./interfaces.sol";

contract Variables {

    // IndexInterface public constant instaIndex = IndexInterface(address(0)); // TODO: update at the time of deployment
    // ListInterface public immutable instaList = ListInterface(address(0)); // TODO: update at the time of deployment

    // address public immutable wchainToken = address(0); // TODO: update at the time of deployment
    address public constant chainToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // TokenInterface public wchainContract = TokenInterface(wchainToken);

    address public constant aaveLendingAddr = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address public constant aaveProtocolDataProviderAddr = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider = IAaveProtocolDataProvider(aaveProtocolDataProviderAddr);

    address public constant balancerLendingAddr = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    // address public constant balancerWeightedPoolFactoryAddr = 0x8E9aa87E45e92bad84D5F8DD1bff34Fb92637dE9;
    // address public constant balancerWeightedPool2TokensFactoryAddr = 0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0;
    // address public constant balancerStablePoolFactoryAddr = 0xc66Ba2B6595D3613CCab350C886aCE23866EDe24;
    // address public constant balancerLiquidityBootstrappingPoolFactoryAddr = 0x751A0bC0e3f75b38e01Cf25bFCE7fF36DE1C87DE;
    // address public constant balancerMetaStablePoolFactoryAddr = 0x67d27634E44793fE63c467035E31ea8635117cd4;
    // address public constant balancerInvestmentPoolFactoryAddr = 0x48767F9F868a4A7b86A90736632F6E44C2df7fa9;
    // IBalancerWeightedPoolFactory public constant balancerWeightedPoolFactory = IBalancerWeightedPoolFactory(balancerWeightedPoolFactoryAddr);
    // IBalancerWeightedPool2TokensFactory public constant balancerWeightedPool2TokensFactory = IBalancerWeightedPool2TokensFactory(balancerWeightedPool2TokensFactoryAddr);
    // IBalancerStablePoolFactory public constant balancerStablePoolFactory = IBalancerStablePoolFactory(balancerStablePoolFactoryAddr);
    // IBalancerLiquidityBootstrappingPoolFactory public constant balancerLiquidityBootstrappingPoolFactory = IBalancerLiquidityBootstrappingPoolFactory(balancerLiquidityBootstrappingPoolFactoryAddr);
    // IBalancerMetaStablePoolFactory public constant balancerMetaStablePoolFactory = IBalancerMetaStablePoolFactory(balancerMetaStablePoolFactoryAddr);
    // IBalancerInvestmentPoolFactory public constant balancerInvestmentPoolFactory = IBalancerInvestmentPoolFactory(balancerInvestmentPoolFactoryAddr);

    address public constant daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 public constant daiBorrowAmount = 500000000000000000000000000;

    address public constant cEthToken = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    InstaFlashloanAggregatorInterface internal flashloanAggregator;

}