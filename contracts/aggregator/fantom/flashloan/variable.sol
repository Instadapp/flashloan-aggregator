//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../../common/variables.sol";

contract ConstantVariables {
    address public constant treasuryAddr =
        0x6C4061A00F8739d528b185CC683B6400E0cd396a;
    address private constant instaListAddr =
        0x10e166c3FAF887D8a61dE6c25039231eE694E926;
    ListInterface public constant instaList = ListInterface(instaListAddr);
}
