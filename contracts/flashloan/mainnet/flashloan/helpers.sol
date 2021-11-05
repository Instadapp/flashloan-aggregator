
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import {Variables} from "./variables.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Helper is Variables {
    using SafeERC20 for IERC20;

    // Helpers
    function SafeApprove(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory fees,
        address receiver
    ) internal {
        require(tokens.length == amounts.length, "Lengths of parameters not same");
        require(tokens.length == fees.length, "Lengths of parameters not same");
        uint256 length = tokens.length;
        IERC20[] memory tokenContracts = new IERC20[](length);
        for (uint i = 0; i < length; i++) {
            tokenContracts[i] = IERC20(tokens[i]);
            tokenContracts[i].safeApprove(receiver, amounts[i] + fees[i]);
        }
    }

    function SafeTransfer(
        address[] memory tokens,
        uint256[] memory amounts,
        address receiver
    ) internal {
        require(tokens.length == amounts.length, "Lengths of parameters not same");
        uint256 length = tokens.length;
        IERC20[] memory tokenContracts = new IERC20[](length);
        for (uint i = 0; i < length; i++) {
            tokenContracts[i] = IERC20(tokens[i]);
            tokenContracts[i].safeTransfer(receiver, amounts[i]);
        }
    }

    function CalculateBalances(
        address account,
        address[] memory tokens
    ) internal returns (uint256[] memory) {
        uint256 _length = tokens.length;
        IERC20[] memory _tokenContracts = new IERC20[](_length);
        uint256[] memory balances = new uint256[](_length);
        for (uint i = 0; i < _length; i++) {
            _tokenContracts[i] = IERC20(tokens[i]);
            balances[i] = _tokenContracts[i].balanceOf(address(this));
        }
    }

    function Validate(
        uint256[] memory iniBals,
        uint256[] memory finBals
    ) internal returns (bool) {
        uint256 _length = iniBals.length;
        for (uint i = 0; i < _length; i++) {
            require(iniBals[i] <= finBals[i], "amount-paid-less");
        }
        return true;
    }
}