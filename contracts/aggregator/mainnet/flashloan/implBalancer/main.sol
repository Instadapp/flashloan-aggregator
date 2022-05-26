//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../helpers.sol";

contract BalancerImplementation is Helper {

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
        require(_route == 5 || _route == 6 || _route == 7, "invalid-BALANCER-route");
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        if (_route == 5) {
            routeBalancer(_tokens, _amounts, _data);
        } else if (_route == 6) {
            routeBalancerCompound(_tokens, _amounts, _data);
        } else if (_route == 7) {
            routeBalancerAave(_tokens, _amounts, _data);
        }
    }

    /**
     * @dev Fallback function for balancer flashloan.
     * @notice Fallback function for balancer flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _fees list of fees for the corresponding addresses for flashloan.
     * @param _data extra data passed(includes route info aswell).
     */
    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        bytes memory _data
    ) external verifyDataHash(_data) {
        require(msg.sender == address(balancerLending), "not-balancer-sender");

        FlashloanVariables memory instaLoanVariables_;

        (
            uint256 route_,
            address[] memory tokens_,
            uint256[] memory amounts_,
            address sender_,
            bytes memory data_
        ) = abi.decode(_data, (uint256, address[], uint256[], address, bytes));

        instaLoanVariables_._tokens = tokens_;
        instaLoanVariables_._amounts = amounts_;
        instaLoanVariables_._iniBals = calculateBalances(
            tokens_,
            address(this)
        );
        instaLoanVariables_._instaFees = calculateFees(
            amounts_,
            calculateFeeBPS(route_, sender_, address(0), 0)
        );

        if (route_ == 5) {
            if (tokens_[0] == stEthTokenAddr) {
                wstEthToken.unwrap(_amounts[0]);
            }
            safeTransfer(instaLoanVariables_, sender_);
            if (checkIfDsa(sender_)) {
                Address.functionCall(
                    sender_,
                    data_,
                    "DSA-flashloan-fallback-failed"
                );
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(
                    tokens_,
                    amounts_,
                    instaLoanVariables_._instaFees,
                    sender_,
                    data_
                );
            }
            if (tokens_[0] == stEthTokenAddr) {
                wstEthToken.wrap(amounts_[0]);
            }

            instaLoanVariables_._finBals = calculateBalances(
                tokens_,
                address(this)
            );
            if (tokens_[0] == stEthTokenAddr) {
                // adding 10 wei to avoid any possible decimal errors in final calculations
                instaLoanVariables_._finBals[0] =
                    instaLoanVariables_._finBals[0] +
                    10;
                instaLoanVariables_._tokens[0] = address(wstEthToken);
                instaLoanVariables_._amounts[0] = _amounts[0];
            }
            validateFlashloan(instaLoanVariables_);
            safeTransferWithFee(
                instaLoanVariables_,
                _fees,
                address(balancerLending)
            );
        } else if (route_ == 6 || route_ == 7) {
            require(_fees[0] == 0, "flash-ETH-fee-not-0");

            address[] memory wEthTokenList = new address[](1);
            wEthTokenList[0] = address(wethToken);

            if (route_ == 6) {
                compoundSupply(wEthTokenList, _amounts);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupply(wEthTokenList, _amounts);
                aaveBorrow(tokens_, amounts_);
            }

            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(sender_)) {
                Address.functionCall(
                    sender_,
                    data_,
                    "DSA-flashloan-fallback-failed"
                );
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(
                    tokens_,
                    amounts_,
                    instaLoanVariables_._instaFees,
                    sender_,
                    data_
                );
            }

            if (route_ == 6) {
                compoundPayback(tokens_, amounts_);
                compoundWithdraw(wEthTokenList, _amounts);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdraw(wEthTokenList, _amounts);
            }
            instaLoanVariables_._finBals = calculateBalances(
                tokens_,
                address(this)
            );
            validateFlashloan(instaLoanVariables_);
            instaLoanVariables_._tokens = wEthTokenList;
            instaLoanVariables_._amounts = _amounts;
            safeTransferWithFee(
                instaLoanVariables_,
                _fees,
                address(balancerLending)
            );
        } else {
            revert("wrong-route");
        }
    }

    /**
     * @dev Middle function for route 5.
     * @notice Middle function for route 5.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeBalancer(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for (uint256 i = 0; i < length_; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        bytes memory data_ = abi.encode(
            5,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        if (_tokens[0] == stEthTokenAddr) {
            require(length_ == 1, "steth-length-should-be-1");
            tokens_[0] = IERC20(address(wstEthToken));
            _amounts[0] = wstEthToken.getWstETHByStETH(_amounts[0]);
        }
        balancerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            tokens_,
            _amounts,
            data_
        );
    }

    /**
     * @dev Middle function for route 6.
     * @notice Middle function for route 6.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeBalancerCompound(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            6,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wethToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            wethTokenList_,
            wethAmountList_,
            data_
        );
    }

    /**
     * @dev Middle function for route 7.
     * @notice Middle function for route 7.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeBalancerAave(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            7,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = wethToken;
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            wethTokenList_,
            wethAmountList_,
            data_
        );
    }
}
