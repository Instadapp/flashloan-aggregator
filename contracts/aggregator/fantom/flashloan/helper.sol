//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../../../common/helpers.sol";
import "./variable.sol";

contract Helper is Variables, HelpersCommon {
    using SafeERC20 for IERC20;

    /**
     * @dev Returns to true if the passed address is a DSA else returns false.
     * @notice Returns to true if the passed address is a DSA else returns false.
     * @param _account account to check for, if DSA.
     */
    function checkIfDsa(address _account) internal view returns (bool) {
        return instaList.accountID(_account) > 0;
    }

    /**
     * @dev Approves the tokens to the receiver address with allowance (amount + fee).
     * @notice Approves the tokens to the receiver address with allowance (amount + fee).
     * @param _instaLoanVariables struct which includes list of token addresses and amounts.
     * @param _fees list of premiums/fees for the corresponding addresses for flashloan.
     * @param _receiver address to which tokens have to be approved.
     */
    function safeApprove(
        FlashloanVariables memory _instaLoanVariables,
        uint256[] memory _fees,
        address _receiver
    ) internal {
        uint256 length_ = _instaLoanVariables._tokens.length;
        require(length_ == _instaLoanVariables._amounts.length, 'Lengths of parameters not same');
        require(length_ == _fees.length, 'Lengths of parameters not same');
        for (uint256 i = 0; i < length_; i++) {
            approve(_instaLoanVariables._tokens[i], _receiver, _instaLoanVariables._amounts[i] + _fees[i]);
        }
    }

    /**
     * @dev Transfers the tokens to the receiver address.
     * @notice Transfers the tokens to the receiver address.
     * @param _instaLoanVariables struct which includes list of token addresses and amounts.
     * @param _receiver address to which tokens have to be transferred.
     */
    function safeTransfer(FlashloanVariables memory _instaLoanVariables, address _receiver) internal {
        uint256 length_ = _instaLoanVariables._tokens.length;
        require(length_ == _instaLoanVariables._amounts.length, 'Lengths of parameters not same');
        for (uint256 i = 0; i < length_; i++) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeTransfer(_receiver, _instaLoanVariables._amounts[i]);
        }
    }

    /**
     * @dev Validates if the receiver sent the correct amounts of funds.
     * @notice Validates if the receiver sent the correct amounts of funds.
     * @param _instaLoanVariables struct which includes list of initial balances, final balances and fees for the respective tokens.
     */
    function validateFlashloan(FlashloanVariables memory _instaLoanVariables) internal pure {
        for (uint256 i = 0; i < _instaLoanVariables._iniBals.length; i++) {
            require(
                _instaLoanVariables._iniBals[i] + _instaLoanVariables._instaFees[i] <= _instaLoanVariables._finBals[i],
                'amount-paid-less'
            );
        }
    }

    /**
     * @dev  better checking by double encoding the data.
     * @notice better checking by double encoding the data.
     * @param data_ data passed.
     */
    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        require(dataHash_ == dataHash && dataHash_ != bytes32(0), 'invalid-data-hash');
        require(status == 2, 'already-entered');
        dataHash = bytes32(0);
        _;
        status = 1;
    }

    /**
     * @dev reentrancy gaurd.
     * @notice reentrancy gaurd.
     */
    modifier reentrancy() {
        require(status == 1, 'already-entered');
        status = 2;
        _;
        require(status == 1, 'already-entered');
    }
}
