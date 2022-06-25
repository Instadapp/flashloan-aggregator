//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    address public owner;
    address public flashloanAggregatorAddr =
        0x2b65731A085B55DBe6c7DcC8D717Ac36c00F6d19; //TODO: update
    InstaFlashloanAggregatorInterface public flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);
    mapping(uint256 => address) routeToResolver;
}
