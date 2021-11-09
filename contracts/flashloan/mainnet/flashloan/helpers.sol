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
        address[] memory tokens,
        address account
    ) internal view returns (uint256[] memory) {
        uint256 _length = tokens.length;
        uint256[] memory balances = new uint256[](_length);
        for (uint i = 0; i < _length; i++) {
            IERC20 token = IERC20(tokens[i]);
            balances[i] = token.balanceOf(account);
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

    function compoundSupplyDAI(uint256 amount) internal {
        CTokenInterface cToken = CTokenInterface(cDaiToken);
        // Approved already in addTokenToctoken function
        require(cToken.mint(amount) == 0, "mint failed");
        address[] memory cTokens = new address[](1);
        cTokens[0] = cDaiToken;
        uint[] memory errors = troller.enterMarkets(cTokens);
        for(uint i=0; i<errors.length; i++){
            require(errors[i] == 0, "Comptroller.enterMarkets failed.");
        }
    }

    function compoundBorrow(
        address[] memory tokens,
        uint256[] memory amounts
    ) internal {
        uint256 length = tokens.length;
        for(uint i=0; i < length; i++) {
            CTokenInterface cToken = CTokenInterface(tokenToCToken[tokens[i]]);
            require(cToken.borrow(amounts[i]) == 0, "borrow failed");
        }
    }

    function compoundPayback(
        address[] memory tokens,
        uint256[] memory amounts
    ) internal {
        uint256 length = tokens.length;
        for(uint i=0; i < length; i++) {
            CTokenInterface cToken = CTokenInterface(tokenToCToken[tokens[i]]);
            // Approved already in addTokenToctoken function
            require(cToken.repayBorrow(amounts[i]) == 0, "repay failed");
        }
    }

    function compoundWithdrawDAI(uint256 amount) internal {
        IERC20 token = IERC20(daiToken);
        CTokenInterface cToken = CTokenInterface(cDaiToken);    
        require(token.approve(cDaiToken, amount), "Approve Failed");
        require(cToken.redeemUnderlying(amount) == 0, "redeem failed");
    }

    function aaveSupplyDAI(uint256 amount) internal {
        IERC20 token = IERC20(daiToken);
        token.safeApprove(aaveLendingAddr, amount);
        aaveLending.deposit(daiToken, amount, address(this), 3228);
        aaveLending.setUserUseReserveAsCollateral(daiToken, true);
    }

    function aaveBorrow(
        address[] memory tokens,
        uint256[] memory amounts
    ) internal {
        uint256 length = tokens.length;
        for(uint i=0; i < length; i++) {
            aaveLending.borrow(tokens[i], amounts[i], 2, 3228, address(this));
        }
    }

    function aavePayback(
        address[] memory tokens,
        uint256[] memory amounts
    ) internal {
        uint256 length = tokens.length;
        for(uint i=0; i < length; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.safeApprove(aaveLendingAddr, amounts[i]);
            aaveLending.repay(tokens[i], amounts[i], 2, address(this));
        }
    }

    function aaveWithdrawDAI(uint256 amount) internal {
        IERC20 token = IERC20(daiToken);   
        require(token.approve(aaveLendingAddr, amount), "Approve Failed");
        aaveLending.withdraw(daiToken, amount, address(this));
    }

    function calculateFeeBPS(uint256 route) internal view returns(uint256 BPS){
        if (route == 1) {
            BPS = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
        } else if (route == 2 || route == 3 || route == 4) {
            BPS = (makerLending.toll()) / (10 ** 14);
        } else {
            require(false, "Invalid source");
        }
        
        if (BPS < InstaFeeBPS) {
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