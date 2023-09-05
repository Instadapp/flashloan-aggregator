//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./helpers.sol";

contract AdvancedRouteImplementation is Helper {

    /**
     * @dev Function to supply and borrow from Compound.
     * @notice Middle helper function for route 6.
     * @param _supplyTokens token addresses for supplying.
     * @param _supplyAmounts list of amounts for the corresponding assets.
     * @param _borrowTokens token addresses for borrowing.
     * @param _borrowAmounts list of amounts for the corresponding assets.
    */
    function compoundSupplyAndBorrow(
        address[] memory _supplyTokens,
        uint256[] memory _supplyAmounts,
        address[] memory _borrowTokens,
        uint256[] memory _borrowAmounts
    ) public {
        compoundSupply(_supplyTokens, _supplyAmounts);
        compoundBorrow(_borrowTokens, _borrowAmounts);
    }

    /**
     * @dev Function to payback and withdraw from Compound.
     * @notice Middle function for route 6.
     * @param _paybackTokens token addresses for payback.
     * @param _paybackAmounts list of amounts for the corresponding assets.
     * @param _withdrawTokens token addresses for withdraw.
     * @param _withdrawAmounts list of amounts for the corresponding assets.
    */
    function compoundPaybackAndWithdraw(
        address[] memory _paybackTokens,
        uint256[] memory _paybackAmounts,
        address[] memory _withdrawTokens,
        uint256[] memory _withdrawAmounts
    ) public {
        compoundPayback(_paybackTokens, _paybackAmounts);
        compoundWithdraw(_withdrawTokens, _withdrawAmounts);
    }

    /**
     * @dev Function to supply and borrow from Aave.
     * @notice Middle helper function for route 7.
     * @param _supplyTokens token addresses for supplying.
     * @param _supplyAmounts list of amounts for the corresponding assets.
     * @param _borrowTokens token addresses for borrowing.
     * @param _borrowAmounts list of amounts for the corresponding assets.
    */
    function aaveSupplyAndBorrow(
        address[] memory _supplyTokens,
        uint256[] memory _supplyAmounts,
        address[] memory _borrowTokens,
        uint256[] memory _borrowAmounts
    ) public {
        aaveSupply(_supplyTokens, _supplyAmounts);
        aaveBorrow(_borrowTokens, _borrowAmounts);
    }

    /**
     * @dev Function to payback and withdraw from Aave.
     * @notice Middle function for route 7.
     * @param _paybackTokens token addresses for payback.
     * @param _paybackAmounts list of amounts for the corresponding assets.
     * @param _withdrawTokens token addresses for withdraw.
     * @param _withdrawAmounts list of amounts for the corresponding assets.
    */
    function aavePaybackAndWithdraw(
        address[] memory _paybackTokens,
        uint256[] memory _paybackAmounts,
        address[] memory _withdrawTokens,
        uint256[] memory _withdrawAmounts
    ) public {
        aavePayback(_paybackTokens, _paybackAmounts);
        aaveWithdraw(_withdrawTokens, _withdrawAmounts);
    }
}