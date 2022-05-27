//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../helpers.sol";

contract FLAImplementation is Helper {

    /**
     * @dev Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @notice Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _route route for flashloan.
     * @param _data extra data passed.
     */
    function flashLoan(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data,
        bytes calldata // kept for future use by instadapp. Currently not used anywhere.
    ) external reentrancy {
        require(_route == 9, "invalid-FLA-route");
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);
        routeFLA(_tokens, _amounts, _data);
    }

    function routeFLA(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal returns (bool) {

        FlashloanVariables memory instaLoanVariables_;
        instaLoanVariables_._tokens = _tokens;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(9, msg.sender)
        );
        instaLoanVariables_._iniBals = calculateBalances(
            _tokens,
            address(this)
        );
        safeTransfer(instaLoanVariables_, msg.sender);

        if (checkIfDsa(msg.sender)) {
            Address.functionCall(
                msg.sender,
                _data,
                "DSA-flashloan-fallback-failed"
            );
        } else {
            require(InstaFlashReceiverInterface(msg.sender).executeOperation(
                _tokens,
                _amounts,
                instaLoanVariables_._instaFees,
                msg.sender,
                _data
            ), "invalid flashloan execution");
        }

        instaLoanVariables_._finBals = calculateBalances(
            _tokens,
            address(this)
        );
        validateFlashloan(instaLoanVariables_);

        return true;
    }

//     function routeFLA(
//         address[] memory _tokens,
//         uint256[] memory _amounts,
//         bytes memory _data
//     ) internal {
//         bytes memory data_ = abi.encode(msg.sender, _data);
//         uint256 length_ = _tokens.length;
//         uint256[] memory _modes = new uint256[](length_);
//         for (uint256 i = 0; i < length_; i++) {
//             _modes[i] = 0;
//         }
//         dataHash = bytes32(keccak256(data_));
//         aaveLending.flashLoan(
//             address(this),
//             _tokens,
//             _amounts,
//             _modes,
//             address(0),
//             data_,
//             3228
//         );
//         for (uint256 i = 0; i < length_; i++) {
//             require(vaultFactory.tokenToVault(token) != address(0), 'FLASH_LENDER_UNSUPPORTED_CURRENCY');
//         }
//         Vault vault = Vault(vaultFactory.tokenToVault(token));
//         require(vault.isPaused() == false, 'VAULT_IS_PAUSED');
//         require(amount > vault.minAmountForFlash(), 'FLASH_VALUE_IS_LESS_THAN_MIN_AMOUNT');
//         require(
//             amount <= vault.stakedToken().balanceOf(address(vault)),
//             'AMOUNT_BIGGER_THAN_BALANCE'
//         );
//         uint256 fee = _flashFee(token, amount);
//         require(vault.transferToAccount(address(receiver), amount), 'FLASH_LENDER_TRANSFER_FAILED');
//         require(
//             receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
//             'FLASH_LENDER_CALLBACK_FAILED'
//         );
//         require(
//             ERC20(vault.stakedToken()).transferFrom(
//                 address(receiver),
//                 address(vault),
//                 amount + fee
//             ),
//             'FLASH_LENDER_REPAY_FAILED'
//         );
//         uint256 treasuryFee = vault.splitFees(fee);
//         emit FlashLoan(address(receiver), token, amount, fee, treasuryFee);
//         return true;
//     }
// }


// /**
//    * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
//    * as long as the amount taken plus a fee is returned.
//    * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
//    * For further details please visit https://developers.aave.com
//    * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
//    * @param assets The addresses of the assets being flash-borrowed
//    * @param amounts The amounts amounts being flash-borrowed
//    * @param modes Types of the debt to open if the flash loan is not returned:
//    *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
//    *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
//    *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
//    * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
//    * @param params Variadic packed params to pass to the receiver as extra information
//    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
//    *   0 if the action is executed directly by the user, without any middle-man
//    **/
//   function flashLoann(
//     address receiverAddress,
//     address[] calldata assets,
//     uint256[] calldata amounts,
//     uint256[] calldata modes,
//     address onBehalfOf,
//     bytes calldata params,
//     uint16 referralCode
//   ) override whenNotPaused {
//     FlashLoanLocalVars memory vars;

//     ValidationLogic.validateFlashloan(assets, amounts);

//     address[] memory aTokenAddresses = new address[](assets.length);
//     uint256[] memory premiums = new uint256[](assets.length);

//     vars.receiver = IFlashLoanReceiver(receiverAddress);

//     for (vars.i = 0; vars.i < assets.length; vars.i++) {
//       aTokenAddresses[vars.i] = _reserves[assets[vars.i]].aTokenAddress;

//       premiums[vars.i] = amounts[vars.i].mul(FLASHLOAN_PREMIUM_TOTAL).div(10000);

//       IAToken(aTokenAddresses[vars.i]).transferUnderlyingTo(receiverAddress, amounts[vars.i]);
//     }

//     require(
//       vars.receiver.executeOperation(assets, amounts, premiums, msg.sender, params),
//       Errors.LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN
//     );

//     for (vars.i = 0; vars.i < assets.length; vars.i++) {
//       vars.currentAsset = assets[vars.i];
//       vars.currentAmount = amounts[vars.i];
//       vars.currentPremium = premiums[vars.i];
//       vars.currentATokenAddress = aTokenAddresses[vars.i];
//       vars.currentAmountPlusPremium = vars.currentAmount.add(vars.currentPremium);

//       if (DataTypes.InterestRateMode(modes[vars.i]) == DataTypes.InterestRateMode.NONE) {
//         _reserves[vars.currentAsset].updateState();
//         _reserves[vars.currentAsset].cumulateToLiquidityIndex(
//           IERC20(vars.currentATokenAddress).totalSupply(),
//           vars.currentPremium
//         );
//         _reserves[vars.currentAsset].updateInterestRates(
//           vars.currentAsset,
//           vars.currentATokenAddress,
//           vars.currentAmountPlusPremium,
//           0
//         );

//         IERC20(vars.currentAsset).safeTransferFrom(
//           receiverAddress,
//           vars.currentATokenAddress,
//           vars.currentAmountPlusPremium
//         );
//       } else {
//         // If the user chose to not return the funds, the system checks if there is enough collateral and
//         // eventually opens a debt position
//         _executeBorrow(
//           ExecuteBorrowParams(
//             vars.currentAsset,
//             msg.sender,
//             onBehalfOf,
//             vars.currentAmount,
//             modes[vars.i],
//             vars.currentATokenAddress,
//             referralCode,
//             false
//           )
//         );
//       }
//       emit FlashLoan(
//         receiverAddress,
//         msg.sender,
//         vars.currentAsset,
//         vars.currentAmount,
//         vars.currentPremium,
//         referralCode
//       );
//     }
//   }
}