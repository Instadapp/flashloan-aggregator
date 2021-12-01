//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    InstaFlashloanAggregatorInterface
} from "./interfaces.sol";

contract Variables {

    address public constant balancerLendingAddr = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    address private flashloanAggregatorAddr = 0x1f882522DF99820dF8e586b6df8bAae2b91a782d;
    InstaFlashloanAggregatorInterface internal flashloanAggregator = InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);

}