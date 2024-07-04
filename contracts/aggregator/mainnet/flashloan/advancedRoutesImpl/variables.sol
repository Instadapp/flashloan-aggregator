//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract ConstantVariables {
    address public constant aaveV2LendingAddr =
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    IAaveLending public constant aaveV2Lending =
        IAaveLending(aaveV2LendingAddr);

    IERC3156FlashLender internal constant makerLending =
        IERC3156FlashLender(0x60744434d6339a6B27d73d9Eda62b6F66a0a04FA);

    IBalancerLending internal constant balancerLending =
        IBalancerLending(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant daiTokenAddr =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 internal constant daiBorrowAmount = 500000000000000000000000000;
    address internal constant cethTokenAddr =
        0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    uint256 internal constant wethBorrowAmountPercentage = 80;
    IWeth internal constant wethToken =
        IWeth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
}
