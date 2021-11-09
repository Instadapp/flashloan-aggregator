//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import {Variables} from "./variables.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { 
    IndexInterface,
    ListInterface,
    TokenInterface,
    IAaveLending, 
    InstaFlashReceiverInterface
} from "./interfaces.sol";

contract Helper is Variables {
    using SafeERC20 for IERC20;

    // Helpers
    function safeApprove(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory fees,
        address receiver
    ) internal {
        require(tokens.length == amounts.length, "Lengths of parameters not same");
        require(tokens.length == fees.length, "Lengths of parameters not same");
        uint256 length = tokens.length;
        for (uint i = 0; i < length; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.safeApprove(receiver, amounts[i] + fees[i]);
        }
    }

    function safeTransfer(
        address[] memory tokens,
        uint256[] memory amounts,
        address receiver
    ) internal {
        require(tokens.length == amounts.length, "Lengths of parameters not same");
        uint256 length = tokens.length;
        for (uint i = 0; i < length; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.safeTransfer(receiver, amounts[i]);
        }
    }

    function calculateBalances(
        address account,
        address[] memory tokens
    ) internal view returns (uint256[] memory) {
        uint256 _length = tokens.length;
        IERC20[] memory _tokenContracts = new IERC20[](_length);
        uint256[] memory balances = new uint256[](_length);
        for (uint i = 0; i < _length; i++) {
            _tokenContracts[i] = IERC20(tokens[i]);
            balances[i] = _tokenContracts[i].balanceOf(account);
        }
        return balances;
    }

    function validate(
        uint256[] memory iniBals,
        uint256[] memory finBals,
        uint256[] memory fees
    ) internal pure returns (bool) {
        uint256 _length = iniBals.length;
        for (uint i = 0; i < _length; i++) {
            require(iniBals[i] + fees[i] <= finBals[i], "amount-paid-less");
        }
        return true;
    }

    function calculateFeeBPS(uint256 route) internal view returns(uint256 BPS){
        if(route == 1) {
            BPS = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
        } else {
            require(false, "Invalid source");
        }
        if(BPS < InstaFeeBPS) {
            BPS = InstaFeeBPS;
        }
    }

    function calculateFees(uint256[] memory amounts, uint256 BPS) internal pure returns (uint256[] memory) {
        uint256 length = amounts.length;
        uint256[] memory InstaFees = new uint256[](length);
        for (uint i = 0; i < length; i++) {
            InstaFees[i] = (amounts[i] * BPS) / (10 ** 4);
        }
        return InstaFees;
    }
}