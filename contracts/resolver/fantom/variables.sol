//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces.sol";

contract Variables {
    uint256 internal status;
    address public owner;
    address public flashloanAggregatorAddr =
        0x22ed23Cc6EFf065AfDb7D5fF0CBf6886fd19aee1;
    InstaFlashloanAggregatorInterface public flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
    mapping(uint256 => address) public routeToResolver;
}
