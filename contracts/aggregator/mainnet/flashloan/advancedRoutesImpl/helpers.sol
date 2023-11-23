//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./variables.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Helper is ConstantVariables {
    using SafeERC20 for IERC20;

    function calculateAndReadFromStorage(address key_) public view returns (address result_) {
        bytes32 slot_ = keccak256(abi.encode(key_, 2)); // Slot for `tokenToCToken` variable

        assembly {
            result_ := sload(slot_) // read value from the storage slot
        }
    }

    /**
     * @dev Approves the token to the spender address with allowance amount.
     * @notice Approves the token to the spender address with allowance amount.
     * @param token_ token for which allowance is to be given.
     * @param spender_ the address to which the allowance is to be given.
     * @param amount_ amount of token.
     */
    function approve(
        address token_,
        address spender_,
        uint256 amount_
    ) internal {
        TokenInterface tokenContract_ = TokenInterface(token_);
        try tokenContract_.approve(spender_, amount_) {} catch {
            IERC20 token = IERC20(token_);
            token.safeApprove(spender_, 0);
            token.safeApprove(spender_, amount_);
        }
    }

    /**
     * @dev Supply tokens for the amounts to compound.
     * @notice Supply tokens for the amounts to compound.
     * @param _tokens token addresses.
     * @param _amounts amounts of tokens.
     */
    function compoundSupply(address[] memory _tokens, uint256[] memory _amounts)
        internal
    {
        uint256 length_ = _tokens.length;
        require(_amounts.length == length_, "array-lengths-not-same");
        address[] memory cTokens_ = new address[](length_);
        for (uint256 i = 0; i < length_; i++) {
            if (_tokens[i] == address(wethToken)) {
                wethToken.withdraw(_amounts[i]);
                CEthInterface cEth_ = CEthInterface(cethTokenAddr);
                cEth_.mint{value: _amounts[i]}();
                cTokens_[i] = cethTokenAddr;
            } else {
                address cTokenAddress_ = calculateAndReadFromStorage(_tokens[i]);
                CTokenInterface cToken_ = CTokenInterface(cTokenAddress_);

                // Approved already in addTokenToctoken function
                require(cToken_.mint(_amounts[i]) == 0, "mint failed");
                cTokens_[i] = cTokenAddress_;
            }
        }
    }

    /**
     * @dev Borrow tokens for the amounts to compound.
     * @notice Borrow tokens for the amounts to compound.
     * @param _tokens list of token addresses.
     * @param _amounts amounts of respective tokens.
     */
    function compoundBorrow(address[] memory _tokens, uint256[] memory _amounts)
        internal
    {
        uint256 length_ = _tokens.length;
        require(_amounts.length == length_, "array-lengths-not-same");
        for (uint256 i = 0; i < length_; i++) {
            if (_tokens[i] == address(wethToken)) {
                CEthInterface cEth = CEthInterface(cethTokenAddr);
                require(cEth.borrow(_amounts[i]) == 0, "borrow failed");
                wethToken.deposit{value: _amounts[i]}();
            } else {
                CTokenInterface cToken = CTokenInterface(
                    calculateAndReadFromStorage(_tokens[i])
                );
                require(cToken.borrow(_amounts[i]) == 0, "borrow failed");
            }
        }
    }

    /**
     * @dev Payback tokens for the amounts to compound.
     * @notice Payback tokens for the amounts to compound.
     * @param _tokens list of token addresses.
     * @param _amounts amounts of respective tokens.
     */
    function compoundPayback(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        require(_amounts.length == length_, "array-lengths-not-same");
        for (uint256 i = 0; i < length_; i++) {
            if (_tokens[i] == address(wethToken)) {
                wethToken.withdraw(_amounts[i]);
                CEthInterface cToken = CEthInterface(cethTokenAddr);
                cToken.repayBorrow{value: _amounts[i]}();
            } else {
                CTokenInterface cToken = CTokenInterface(
                    calculateAndReadFromStorage(_tokens[i])
                );
                // Approved already in addTokenToctoken function
                require(cToken.repayBorrow(_amounts[i]) == 0, "repay failed");
            }
        }
    }

    /**
     * @dev Withdraw tokens from compound.
     * @notice Withdraw tokens from compound.
     * @param _tokens token addresses.
     * @param _amounts amounts of tokens.
     */
    function compoundWithdraw(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        require(_amounts.length == length_, "array-lengths-not-same");
        for (uint256 i = 0; i < length_; i++) {
            if (_tokens[i] == address(wethToken)) {
                CEthInterface cEth_ = CEthInterface(cethTokenAddr);
                require(
                    cEth_.redeemUnderlying(_amounts[i]) == 0,
                    "redeem failed"
                );
                wethToken.deposit{value: _amounts[i]}();
            } else {
                CTokenInterface cToken_ = CTokenInterface(
                    calculateAndReadFromStorage(_tokens[i])
                );
                require(
                    cToken_.redeemUnderlying(_amounts[i]) == 0,
                    "redeem failed"
                );
            }
        }
    }

    /**
     * @dev Supply tokens to aave.
     * @notice Supply tokens to aave.
     * @param _tokens token addresses.
     * @param _amounts amounts of tokens.
     */
    function aaveSupply(address[] memory _tokens, uint256[] memory _amounts)
        internal
    {
        uint256 length_ = _tokens.length;
        require(_amounts.length == length_, "array-lengths-not-same");
        for (uint256 i = 0; i < length_; i++) {
            approve(_tokens[i], aaveV2LendingAddr, _amounts[i]);
            aaveV2Lending.deposit(_tokens[i], _amounts[i], address(this), 3228);
            aaveV2Lending.setUserUseReserveAsCollateral(_tokens[i], true);
        }
    }

    /**
     * @dev Borrow tokens from aave.
     * @notice Borrow tokens from aave.
     * @param _tokens list of token addresses.
     * @param _amounts list of amounts for respective tokens.
     */
    function aaveBorrow(address[] memory _tokens, uint256[] memory _amounts)
        internal
    {
        uint256 length_ = _tokens.length;
        require(_amounts.length == length_, "array-lengths-not-same");
        for (uint256 i = 0; i < length_; i++) {
            aaveV2Lending.borrow(_tokens[i], _amounts[i], 2, 3228, address(this));
        }
    }

    /**
     * @dev Payback tokens to aave.
     * @notice Payback tokens to aave.
     * @param _tokens list of token addresses.
     * @param _amounts list of amounts for respective tokens.
     */
    function aavePayback(address[] memory _tokens, uint256[] memory _amounts)
        internal
    {
        uint256 length_ = _tokens.length;
        require(_amounts.length == length_, "array-lengths-not-same");
        for (uint256 i = 0; i < length_; i++) {
            approve(_tokens[i], aaveV2LendingAddr, _amounts[i]);
            aaveV2Lending.repay(_tokens[i], _amounts[i], 2, address(this));
        }
    }

    /**
     * @dev Withdraw tokens from aave.
     * @notice Withdraw tokens from aave.
     * @param _tokens token addresses.
     * @param _amounts amounts of tokens.
     */
    function aaveWithdraw(address[] memory _tokens, uint256[] memory _amounts)
        internal
    {
        uint256 length_ = _tokens.length;
        require(_amounts.length == length_, "array-lengths-not-same");
        for (uint256 i = 0; i < length_; i++) {
            aaveV2Lending.withdraw(_tokens[i], _amounts[i], address(this));
        }
    }

    /**
     * @dev Returns to wEth amount to be borrowed.
     * @notice Returns to wEth amount to be borrowed.
     */
    function getWEthBorrowAmount() internal view returns (uint256) {
        uint256 amount_ = wethToken.balanceOf(address(balancerLending));
        return (amount_ * wethBorrowAmountPercentage) / 100;
    }
}
