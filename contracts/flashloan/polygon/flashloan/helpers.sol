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
    function SafeApprove(
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

    function SafeTransfer(
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

    function CalculateBalances(
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

    function Validate(
        uint256[] memory iniBals,
        uint256[] memory finBals
    ) internal pure returns (bool) {
        uint256 _length = iniBals.length;
        for (uint i = 0; i < _length; i++) {
            require(iniBals[i] <= finBals[i], "amount-paid-less");
        }
        return true;
    }

    // function CompoundSupplyDAI(uint256 amount) internal {
    //     IERC20 token = IERC20(daiToken);
    //     CTokenInterface cToken = CTokenInterface(cDaiToken);
    //     token.safeApprove(cDaiToken, amount);
    //     require(cToken.mint(amount) == 0, "mint failed");
    //     address[] memory cTokens = new address[](1);
    //     cTokens[0] = cDaiToken;
    //     uint[] memory errors = troller.enterMarkets(cTokens);
    //     for(uint i=0; i<errors.length; i++){
    //         require(errors[i] == 0, "Comptroller.enterMarkets failed.");
    //     }
    // }

    // function CompoundBorrow(
    //     address[] memory tokens,
    //     uint256[] memory amounts
    // ) internal {
    //     uint256 length = tokens.length;
    //     for(uint i=0; i < length; i++) {
    //         CTokenInterface cToken = CTokenInterface(tokenToCToken[tokens[i]]);
    //         require(cToken.borrow(amounts[i]) == 0, "borrow failed");
    //     }
    // }

    // function CompoundPayback(
    //     address[] memory tokens,
    //     uint256[] memory amounts
    // ) internal {
    //     uint256 length = tokens.length;
    //     for(uint i=0; i < length; i++) {
    //         IERC20 token = IERC20(tokens[i]);
    //         CTokenInterface cToken = CTokenInterface(tokenToCToken[tokens[i]]);
    //         token.safeApprove(tokenToCToken[tokens[i]], amounts[i]);
    //         require(cToken.repayBorrow(amounts[i]) == 0, "repay failed");
    //     }
    // }

    // function CompoundWithdrawDAI(uint256 amount) internal {
    //     IERC20 token = IERC20(daiToken);
    //     CTokenInterface cToken = CTokenInterface(cDaiToken);    
    //     require(token.approve(cDaiToken, amount), "Approve Failed");
    //     require(cToken.redeemUnderlying(amount) == 0, "redeem failed");
    // }

    // function AaveSupplyDAI(uint256 amount) internal {
    //     IERC20 token = IERC20(daiToken);
    //     token.safeApprove(aaveLendingAddr, amount);
    //     aaveLending.deposit(daiToken, amount, address(this), 3228);
    //     aaveLending.setUserUseReserveAsCollateral(daiToken, true);
    // }

    // function AaveBorrow(
    //     address[] memory tokens,
    //     uint256[] memory amounts
    // ) internal {
    //     uint256 length = tokens.length;
    //     for(uint i=0; i < length; i++) {
    //         aaveLending.borrow(tokens[i], amounts[i], 2, 3228, address(this));
    //     }
    // }

    // function AavePayback(
    //     address[] memory tokens,
    //     uint256[] memory amounts
    // ) internal {
    //     uint256 length = tokens.length;
    //     for(uint i=0; i < length; i++) {
    //         IERC20 token = IERC20(tokens[i]);
    //         token.safeApprove(aaveLendingAddr, amounts[i]);
    //         aaveLending.repay(tokens[i], amounts[i], 2, address(this));
    //     }
    // }

    // function AaveWithdrawDAI(uint256 amount) internal {
    //     IERC20 token = IERC20(daiToken);   
    //     require(token.approve(aaveLendingAddr, amount), "Approve Failed");
    //     aaveLending.withdraw(daiToken, amount, address(this));
    // }

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