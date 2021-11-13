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
    InstaFlashReceiverInterface
} from "./interfaces.sol";

contract Helper is Variables {
    using SafeERC20 for IERC20;

    // Helpers
    function safeApprove(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        address _receiver
    ) internal {
        require(_tokens.length == _amounts.length, "Lengths of parameters not same");
        require(_tokens.length == _fees.length, "Lengths of parameters not same");
        uint256 length_ = _tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.safeApprove(_receiver, _amounts[i] + _fees[i]);
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

    function safeTransferWithFee(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        address _receiver
    ) internal {
        require(_tokens.length == _amounts.length, "Lengths of parameters not same");
        require(_tokens.length == _fees.length, "Lengths of parameters not same");
        uint256 length_ = _tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.safeTransfer(_receiver, _amounts[i] + _fees[i]);
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

    function calculateFeeBPS(uint256 _route) internal view returns (uint256 BPS_) {
        if (_route == 5) {
            BPS_ = (balancerLending.getProtocolFeesCollector().getFlashLoanFeePercentage()) * 100;
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

    function bubbleSort(address[] memory _tokens, uint256[] memory _amounts) internal pure returns (address[] memory, uint256[] memory) {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            for( uint256 j = 0; j < _tokens.length - i - 1 ; j++) {
                if(_tokens[j] > _tokens[j+1]) {
                    (_tokens[j], _tokens[j+1], _amounts[j], _amounts[j+1]) = (_tokens[j+1], _tokens[j], _amounts[j+1], _amounts[j]);
                }
            }
        }
        return (_tokens, _amounts);
    }
}