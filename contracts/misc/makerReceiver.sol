
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

interface IFlashLoan {
    function flashLoan(address[] memory tokens_, uint[] memory amts_,uint256 route, bytes calldata data_) external;
}

contract MakerReceiver {
    using SafeERC20 for IERC20;

    IFlashLoan internal immutable flashloan; // TODO: Contract/Protocol address to get flashloan

    function flashBorrow(address token_, uint amt_, uint256 route, bytes calldata data_) public {
        address[] memory tokens_ = new address[](1);
        uint[] memory amts_ = new uint[](1);
        tokens_[0] = token_;
        flashloan.flashLoan(tokens_, amts_, route, data_);
    }

    // Function which
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        // Do something
        IERC20(token).safeTransfer(address(flashloan), amount + fee);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    constructor(address flashloan_) {
        flashloan = IFlashLoan(flashloan_);
    }

}