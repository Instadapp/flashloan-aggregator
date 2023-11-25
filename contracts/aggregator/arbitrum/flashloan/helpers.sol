//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./variables.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Helper is Variables {
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
        for (uint256 i; i < length_;) {
            approve(
                _instaLoanVariables._tokens[i],
                _receiver,
                _instaLoanVariables._amounts[i] + _fees[i]
            );

            unchecked {
                ++i;
            }
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
        for (uint256 i; i < length_;) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeTransfer(_receiver, _instaLoanVariables._amounts[i]);

            unchecked {
                ++i;
            }
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
        for (uint256 i; i < length_;) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeTransfer(
                _receiver,
                _instaLoanVariables._amounts[i] + _fees[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Calculates the balances..
     * @notice Calculates the balances of the account passed for the tokens.
     * @param _tokens list of token addresses to calculate balance for.
     * @param _account account to calculate balance for.
     */
    function calculateBalances(address[] memory _tokens, address _account)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 _length = _tokens.length;
        uint256[] memory balances_ = new uint256[](_length);
        for (uint256 i; i < _length;) {
            IERC20 token = IERC20(_tokens[i]);
            balances_[i] = token.balanceOf(_account);

            unchecked {
                ++i;
            }
        }
        return balances_;
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
        for (uint256 i; i < _instaLoanVariables._iniBals.length;) {
            require(
                _instaLoanVariables._iniBals[i] +
                    _instaLoanVariables._instaFees[i] <=
                    _instaLoanVariables._finBals[i],
                "amount-paid-less"
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Validates if token addresses are unique. Just need to check adjacent tokens as the array was sorted first
     * @notice Validates if token addresses are unique.
     * @param _tokens list of token addresses.
     */
    function validateTokens(address[] memory _tokens) internal pure {
        for (uint256 i; i < _tokens.length - 1;) {
            require(_tokens[i] != _tokens[i + 1], "non-unique-tokens");
            unchecked {
                ++i;
            }
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
        if (_route == 5) {
            BPS_ =
                (
                    balancerLending
                        .getProtocolFeesCollector()
                        .getFlashLoanFeePercentage()
                ) *
                100;
        } else {
            revert("Invalid source");
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
    function calculateFees(uint256[] memory _amounts, uint256 _BPS)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 length_ = _amounts.length;
        uint256[] memory InstaFees = new uint256[](length_);
        for (uint256 i; i < length_;) {
            InstaFees[i] = (_amounts[i] * _BPS) / (10**4);

            unchecked {
                ++i;
            }
        }
        return InstaFees;
    }

    /**
     * @dev Sort the tokens and amounts arrays according to token addresses.
     * @notice Sort the tokens and amounts arrays according to token addresses.
     * @param _tokens list of token addresses.
     * @param _amounts list of respective amounts.
     */
    function bubbleSort(address[] memory _tokens, uint256[] memory _amounts)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i; i < _tokens.length - 1;) {
            for (uint256 j; j < _tokens.length - i - 1;) {
                if (_tokens[j] > _tokens[j + 1]) {
                    (
                        _tokens[j],
                        _tokens[j + 1],
                        _amounts[j],
                        _amounts[j + 1]
                    ) = (
                        _tokens[j + 1],
                        _tokens[j],
                        _amounts[j + 1],
                        _amounts[j]
                    );
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
        return (_tokens, _amounts);
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
     * @dev  better check by double encoding the data.
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
     * @dev reentrancy guard.
     * @notice reentrancy guard.
     */
    modifier reentrancy() {
        require(status == 1, "already-entered");
        status = 2;
        _;
        require(status == 1, "already-entered");
    }
}
