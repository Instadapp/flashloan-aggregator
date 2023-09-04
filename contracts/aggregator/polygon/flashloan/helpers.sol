//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./variables.sol";
import "../../common/helpers.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Helper is HelpersCommon, Variables {
    using SafeERC20 for IERC20;

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
        require(
            length_ == _instaLoanVariables._amounts.length,
            "Lengths of parameters not same"
        );
        require(length_ == _fees.length, "Lengths of parameters not same");
        for (uint256 i = 0; i < length_; i++) {
            approve(
                _instaLoanVariables._tokens[i],
                _receiver,
                _instaLoanVariables._amounts[i] + _fees[i]
            );
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
        uint256 length_ = _instaLoanVariables._tokens.length;
        require(
            length_ == _instaLoanVariables._amounts.length,
            "Lengths of parameters not same"
        );
        for (uint256 i = 0; i < length_; i++) {
            IERC20 token_ = IERC20(_instaLoanVariables._tokens[i]);
            token_.safeTransfer(_receiver, _instaLoanVariables._amounts[i]);
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
        uint256 length_ = _instaLoanVariables._tokens.length;
        require(
            length_ == _instaLoanVariables._amounts.length,
            "Lengths of parameters not same"
        );
        require(length_ == _fees.length, "Lengths of parameters not same");
        for (uint256 i = 0; i < length_; i++) {
            IERC20 token_ = IERC20(_instaLoanVariables._tokens[i]);
            token_.safeTransfer(
                _receiver,
                _instaLoanVariables._amounts[i] + _fees[i]
            );
        }
    }

    /**
     * @dev Validates if the receiver sent the correct amounts of funds.
     * @notice Validates if the receiver sent the correct amounts of funds.
     * @param _instaLoanVariables struct which includes list of initial balances, final balances and fees for the respective tokens.
     */
    function validateFlashloan(FlashloanVariables memory _instaLoanVariables)
        internal
        pure
    {
        for (uint256 i = 0; i < _instaLoanVariables._iniBals.length; i++) {
            require(
                _instaLoanVariables._iniBals[i] +
                    _instaLoanVariables._instaFees[i] <=
                    _instaLoanVariables._finBals[i],
                "amount-paid-less"
            );
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
            approve(_tokens[i], aaveLendingAddr, _amounts[i]);
            aaveLending.deposit(_tokens[i], _amounts[i], address(this), 3228);
            aaveLending.setUserUseReserveAsCollateral(_tokens[i], true);
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
            aaveLending.borrow(_tokens[i], _amounts[i], 2, 3228, address(this));
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
            approve(_tokens[i], aaveLendingAddr, _amounts[i]);
            aaveLending.repay(_tokens[i], _amounts[i], 2, address(this));
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
            aaveLending.withdraw(_tokens[i], _amounts[i], address(this));
        }
    }

    /**
     * @dev Returns fee for the passed route in BPS.
     * @notice Returns fee for the passed route in BPS. 1 BPS == 0.01%.
     * @param _route route number for flashloan.
     */
    function calculateFeeBPS(uint256 _route)
        public
        view
        returns (uint256 BPS_)
    {
        if (_route == 1) {
            BPS_ = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
        } else if (_route == 5 || _route == 7) {
            BPS_ =
                (
                    balancerLending
                        .getProtocolFeesCollector()
                        .getFlashLoanFeePercentage()
                ) *
                100;
        } else if (_route == 9) {
            BPS_ = InstaFeeBPS;
        } else {
            revert("Invalid source");
        }

        if (BPS_ < InstaFeeBPS) {
            BPS_ = InstaFeeBPS;
        }
    }

    /**
     * @dev Returns to wEth amount to be borrowed.
     * @notice Returns to wEth amount to be borrowed.
     */
    function getWEthBorrowAmount() internal view returns (uint256) {
        IERC20 wEth = IERC20(wEthToken);
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

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1, "Token not sorted");
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev  better checking by double encoding the data.
     * @notice better checking by double encoding the data.
     * @param data_ data passed.
     */
    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        require(
            dataHash_ == dataHash && dataHash_ != bytes32(0),
            "invalid-data-hash"
        );
        require(status == 2, "already-entered");
        dataHash = bytes32(0);
        _;
        status = 1;
    }

    /**
     * @dev reentrancy gaurd.
     * @notice reentrancy gaurd.
     */
    modifier reentrancy() {
        require(status == 1, "already-entered");
        status = 2;
        _;
        require(status == 1, "already-entered");
    }
}
