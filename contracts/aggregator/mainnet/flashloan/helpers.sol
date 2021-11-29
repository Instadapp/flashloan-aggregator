//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Variables} from "./variables.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
    TokenInterface,
    CTokenInterface,
    CEthInterface
} from "./interfaces.sol";

contract Helper is Variables {
    using SafeERC20 for IERC20;

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
        require(_instaLoanVariables._tokens.length == _instaLoanVariables._amounts.length, "Lengths of parameters not same");
        require(_instaLoanVariables._tokens.length == _fees.length, "Lengths of parameters not same");
        uint256 length_ = _instaLoanVariables._tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeApprove(_receiver, _instaLoanVariables._amounts[i] + _fees[i]);
        }
    }

    /**
     * @dev Transfers the tokens to the receiver address.
     * @notice Transfers the tokens to the receiver address.
     * @param _instaLoanVariables struct which includes list of token addresses and amounts.
     * @param _receiver address to which tokens have to be transferred.
    */
    function safeTransfer(
        FlashloanVariables memory _instaLoanVariables,
        address _receiver
    ) internal {
        require(_instaLoanVariables._tokens.length == _instaLoanVariables._amounts.length, "Lengths of parameters not same");
        uint256 length_ = _instaLoanVariables._tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeTransfer(_receiver, _instaLoanVariables._amounts[i]);
        }
    }

    /**
     * @dev Transfers the tokens to the receiver address (amount + fee).
     * @notice Transfers the tokens to the receiver address (amount + fee).
     * @param _instaLoanVariables struct which includes list of token addresses and amounts.
     * @param _fees list of fees for the respective tokens.
     * @param _receiver address to which tokens have to be transferred.
    */
    function safeTransferWithFee(
        FlashloanVariables memory _instaLoanVariables,
        uint256[] memory _fees,
        address _receiver
    ) internal {
        require(_instaLoanVariables._tokens.length == _instaLoanVariables._amounts.length, "Lengths of parameters not same");
        require(_instaLoanVariables._tokens.length == _fees.length, "Lengths of parameters not same");
        uint256 length_ = _instaLoanVariables._tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeTransfer(_receiver, _instaLoanVariables._amounts[i] + _fees[i]);
        }
    }

    /**
     * @dev Calculates the balances..
     * @notice Calculates the balances of the account passed for the tokens.
     * @param _tokens list of token addresses to calculate balance for.
     * @param _account account to calculate balance for.
    */
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

    /**
     * @dev Validates if the receiver sent the correct amounts of funds.
     * @notice Validates if the receiver sent the correct amounts of funds.
     * @param _instaLoanVariables struct which includes list of initial balances, final balances and fees for the respective tokens.
    */
    function validateFlashloan(
        FlashloanVariables memory _instaLoanVariables
    ) internal pure {
        for (uint i = 0; i < _instaLoanVariables._iniBals.length; i++) {
            require(_instaLoanVariables._iniBals[i] + _instaLoanVariables._instaFees[i] <= _instaLoanVariables._finBals[i], "amount-paid-less");
        }
    }

    /**
     * @dev Validates if token addresses are unique. Just need to check adjacent tokens as the array was sorted first
     * @notice Validates if token addresses are unique.
     * @param _tokens list of token addresses.
    */
    function validateTokens(address[] memory _tokens) internal pure {
        for (uint i = 0; i < _tokens.length - 1; i++) {
            require(_tokens[i] != _tokens[i+1], "non-unique-tokens");
        }
    }

    /**
     * @dev Supply token for the amount to compound.
     * @notice Supply token for the amount to compound.
     * @param _token token addresses.
     * @param _amount amount of token.
    */
    function compoundSupply(address _token, uint256 _amount) internal {
        address[] memory cTokens_ = new address[](1);
        if (_token == wEthToken) {
            wEth.withdraw(_amount);
            CEthInterface cEth_ = CEthInterface(cEthToken);
            cEth_.mint{value: _amount}();
            cTokens_[0] = cEthToken;
        } else {
            CTokenInterface cToken_ = CTokenInterface(tokenToCToken[_token]);
            // Approved already in addTokenToctoken function
            require(cToken_.mint(_amount) == 0, "mint failed");
            cTokens_[0] = tokenToCToken[_token];
        }
        uint[] memory errors_ = troller.enterMarkets(cTokens_);
        for(uint i=0; i < errors_.length; i++){
            require(errors_[i] == 0, "Comptroller.enterMarkets failed.");
        }
    }

    /**
     * @dev Borrow tokens for the amounts to compound.
     * @notice Borrow tokens for the amounts to compound.
     * @param _tokens list of token addresses.
     * @param _amounts amounts of respective tokens.
    */
    function compoundBorrow(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        for(uint i=0; i < length_; i++) {
            if (_tokens[i] == wEthToken) {
                CEthInterface cEth = CEthInterface(cEthToken);
                require(cEth.borrow(_amounts[i]) == 0, "borrow failed");
                wEth.deposit{value: _amounts[i]}();
            } else {
                CTokenInterface cToken = CTokenInterface(tokenToCToken[_tokens[i]]);
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
        for(uint i=0; i < length_; i++) {
            if ( _tokens[i] == wEthToken ) {
                wEth.withdraw(_amounts[i]);
                CEthInterface cToken = CEthInterface(cEthToken);
                cToken.repayBorrow{value : _amounts[i]}();
            } else {
                CTokenInterface cToken = CTokenInterface(tokenToCToken[_tokens[i]]);
                // Approved already in addTokenToctoken function
                require(cToken.repayBorrow(_amounts[i]) == 0, "repay failed");
            }
        }
    }

    /**
     * @dev Withdraw token from compound.
     * @notice Withdraw token from compound.
     * @param _token token address.
     * @param _amount amount of token.
    */
    function compoundWithdraw(address _token, uint256 _amount) internal {
        if (_token == wEthToken) {
            CEthInterface cEth_ = CEthInterface(cEthToken);
            require(cEth_.redeemUnderlying(_amount) == 0, "redeem failed");
            wEth.deposit{value: _amount}();
        } else {
            CTokenInterface cToken_ = CTokenInterface(tokenToCToken[_token]);    
            require(cToken_.redeemUnderlying(_amount) == 0, "redeem failed");
        }
    }

    /**
     * @dev Supply token to aave.
     * @notice Supply token to aave.
     * @param _token token address.
     * @param _amount amount of token.
    */
    function aaveSupply(address _token, uint256 _amount) internal {
        IERC20 token_ = IERC20(_token);
        token_.safeApprove(aaveLendingAddr, _amount);
        aaveLending.deposit(_token, _amount, address(this), 3228);
        aaveLending.setUserUseReserveAsCollateral(_token, true);
    }

    /**
     * @dev Borrow tokens from aave.
     * @notice Borrow tokens from aave.
     * @param _tokens list of token addresses.
     * @param _amounts list of amounts for respective tokens.
    */
    function aaveBorrow(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        for(uint i=0; i < length_; i++) {
            aaveLending.borrow(_tokens[i], _amounts[i], 2, 3228, address(this));
        }
    }

    /**
     * @dev Payback tokens to aave.
     * @notice Payback tokens to aave.
     * @param _tokens list of token addresses.
     * @param _amounts list of amounts for respective tokens.
    */
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

    /**
     * @dev Withdraw token from aave.
     * @notice Wiothdraw token from aave.
     * @param _token token address.
     * @param _amount amount of token.
    */
    function aaveWithdraw(address _token, uint256 _amount) internal {
        aaveLending.withdraw(_token, _amount, address(this));
    }

    /**
     * @dev Returns fee for the passed route in BPS.
     * @notice Returns fee for the passed route in BPS. 1 BPS == 0.01%.
     * @param _route route number for flashloan.
    */
    function calculateFeeBPS(uint256 _route) public view returns (uint256 BPS_) {
        if (_route == 1) {
            BPS_ = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
        } else if (_route == 2 || _route == 3 || _route == 4) {
            BPS_ = (makerLending.toll()) / (10 ** 14);
        } else if (_route == 5 || _route == 6 || _route == 7) {
            BPS_ = (balancerLending.getProtocolFeesCollector().getFlashLoanFeePercentage()) * 100;
        } else {
            require(false, "Invalid source");
        }
        
        if (BPS_ < InstaFeeBPS) {
            BPS_ = InstaFeeBPS;
        }
    }

    /**
     * @dev Calculate fees for the respective amounts and fee in BPS passed.
     * @notice Calculate fees for the respective amounts and fee in BPS passed. 1 BPS == 0.01%.
     * @param _amounts list of amounts.
     * @param _BPS fee in BPS.
    */
    function calculateFees(uint256[] memory _amounts, uint256 _BPS) internal pure returns (uint256[] memory) {
        uint256 length_ = _amounts.length;
        uint256[] memory InstaFees = new uint256[](length_);
        for (uint i = 0; i < length_; i++) {
            InstaFees[i] = (_amounts[i] * _BPS) / (10 ** 4);
        }
        return InstaFees;
    }

    /**
     * @dev Sort the tokens and amounts arrays according to token addresses.
     * @notice Sort the tokens and amounts arrays according to token addresses.
     * @param _tokens list of token addresses.
     * @param _amounts list of respective amounts.
    */
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

    /**
     * @dev Returns to wEth amount to be borrowed.
     * @notice Returns to wEth amount to be borrowed.
    */
    function getWEthBorrowAmount() internal view returns (uint256) {
        uint256 amount_ = wEth.balanceOf(balancerLendingAddr);
        return (amount_ * wethBorrowAmountPercentage) / 100;
    }
    
    /**
     * @dev Returns to true if the passed address is a DSA else returns false.
     * @notice Returns to true if the passed address is a DSA else returns false.
     * @param _account account to check for, if DSA.
    */
    function checkIfDsa(address _account) internal view returns (bool) {
        return instaList.accountID(_account) > 0;
    }

    /**
     * @dev  better checking by double encoding the data.
     * @notice better checking by double encoding the data.
     * @param data_ data passed.
    */
    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        require(dataHash_ == dataHash && dataHash_ != bytes32(0), "invalid-data-hash");
        require(status == 2, "already-entered");
        dataHash = bytes32(0);
        _;
        status = 1;
    }

    /**
     * @dev reentrancy gaurd.
     * @notice reentrancy gaurd.
    */
    modifier reentrancy {
        require(status == 1, "already-entered");
        status = 2;
        _;
        require(status == 1, "already-entered");
    }
}