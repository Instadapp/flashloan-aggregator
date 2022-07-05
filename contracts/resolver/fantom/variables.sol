//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces.sol";

contract Variables {
    address public owner = 
        0x34Eb8e4B8789807540eB188459ccE082D642e846;
    address public flashloanAggregatorAddr =
        0x22ed23Cc6EFf065AfDb7D5fF0CBf6886fd19aee1;
    InstaFlashloanAggregatorInterface public flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
    mapping(uint256 => address) routeToResolver;
}
