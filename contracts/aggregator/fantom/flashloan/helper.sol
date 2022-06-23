//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import '../../common/helpers.sol';
import './variable.sol';

contract Helper is ConstantVariables, HelpersCommon {
    /**
     * @dev Returns to true if the passed address is a DSA else returns false.
     * @notice Returns to true if the passed address is a DSA else returns false.
     * @param _account account to check for, if DSA.
     */
    function checkIfDsa(address _account) internal view returns (bool) {
        return instaList.accountID(_account) > 0;
    }
}
