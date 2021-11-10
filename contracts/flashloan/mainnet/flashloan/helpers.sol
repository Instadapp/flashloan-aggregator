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
    CTokenInterface,
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

    function compoundSupplyDAI(uint256 _amount) internal {
        CTokenInterface cToken_ = CTokenInterface(cDaiToken);
        // Approved already in addTokenToctoken function
        require(cToken_.mint(_amount) == 0, "mint failed");
        address[] memory cTokens_ = new address[](1);
        cTokens_[0] = cDaiToken;
        uint[] memory errors_ = troller.enterMarkets(cTokens_);
        for(uint i=0; i < errors_.length; i++){
            require(errors_[i] == 0, "Comptroller.enterMarkets failed.");
        }
    }

    function compoundBorrow(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        for(uint i=0; i < length_; i++) {
            CTokenInterface cToken = CTokenInterface(tokenToCToken[_tokens[i]]);
            require(cToken.borrow(_amounts[i]) == 0, "borrow failed");
        }
    }

    function compoundPayback(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        for(uint i=0; i < length_; i++) {
            CTokenInterface cToken = CTokenInterface(tokenToCToken[_tokens[i]]);
            // Approved already in addTokenToctoken function
            require(cToken.repayBorrow(_amounts[i]) == 0, "repay failed");
        }
    }

    function compoundWithdrawDAI(uint256 _amount) internal {
        IERC20 token_ = IERC20(daiToken);
        CTokenInterface cToken_ = CTokenInterface(cDaiToken);    
        require(token_.approve(cDaiToken, _amount), "Approve Failed");
        require(cToken_.redeemUnderlying(_amount) == 0, "redeem failed");
    }

    function aaveSupplyDAI(uint256 _amount) internal {
        IERC20 token_ = IERC20(daiToken);
        token_.safeApprove(aaveLendingAddr, _amount);
        aaveLending.deposit(daiToken, _amount, address(this), 3228);
        aaveLending.setUserUseReserveAsCollateral(daiToken, true);
    }

    function aaveBorrow(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        for(uint i=0; i < length_; i++) {
            aaveLending.borrow(_tokens[i], _amounts[i], 2, 3228, address(this));
        }
    }

    function aavePayback(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length = _tokens.length;
        for(uint i=0; i < length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            token_.safeApprove(aaveLendingAddr, _amounts[i]);
            aaveLending.repay(_tokens[i], _amounts[i], 2, address(this));
        }
    }

    function aaveWithdrawDAI(uint256 _amount) internal {
        IERC20 token_ = IERC20(daiToken);   
        require(token_.approve(aaveLendingAddr, _amount), "Approve Failed");
        aaveLending.withdraw(daiToken, _amount, address(this));
    }

    function calculateFeeBPS(uint256 _route) internal view returns(uint256 BPS_){
        if (_route == 1) {
            BPS_ = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
        } else if (_route == 2 || _route == 3 || _route == 4) {
            BPS_ = (makerLending.toll()) / (10 ** 14);
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