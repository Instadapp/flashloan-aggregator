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
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        address receiver
    ) internal {
        require(_tokens.length == _amounts.length, "Lengths of parameters not same");
        require(_tokens.length == _fees.length, "Lengths of parameters not same");
        uint256 length = _tokens.length;
        for (uint i = 0; i < length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.safeApprove(receiver, _amounts[i] + _fees[i]);
        }
    }

    function safeTransfer(
        address[] memory _tokens,
        uint256[] memory _amounts,
        address _receiver
    ) internal {
        require(_tokens.length == _amounts.length, "Lengths of parameters not same");
        uint256 length_ = _tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.safeTransfer(_receiver, _amounts[i]);
        }
    }

    function calculateBalances(
        address[] memory _tokens,
        address _account
    ) internal view returns (uint256[] memory) {
        uint256 _length = _tokens.length;
        uint256[] memory balances_ = new uint256[](_length);
        for (uint i = 0; i < _length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            balances_[i] = token.balanceOf(_account);
        }
        return balances_;
    }

    function validate(
        uint256[] memory _iniBals,
        uint256[] memory _finBals,
        uint256[] memory _fees
    ) internal pure returns (bool) {
        uint256 length_ = _iniBals.length;
        for (uint i = 0; i < length_; i++) {
            require(_iniBals[i] + _fees[i] <= _finBals[i], "amount-paid-less");
        }
        return true;
    }

    function calculateFeeBPS(uint256 _route) public view returns(uint256 BPS_){
        if (_route == 1) {
            BPS_ = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
        } else {
            require(false, "Invalid source");
        }
        
        if (BPS_ < InstaFeeBPS) {
            BPS_ = InstaFeeBPS;
        }
    }

    function calculateFees(uint256[] memory _amounts, uint256 _BPS) internal pure returns (uint256[] memory) {
        uint256 length_ = _amounts.length;
        uint256[] memory InstaFees = new uint256[](length_);
        for (uint i = 0; i < length_; i++) {
            InstaFees[i] = (_amounts[i] * _BPS) / (10 ** 4);
        }
        return InstaFees;
    }
}