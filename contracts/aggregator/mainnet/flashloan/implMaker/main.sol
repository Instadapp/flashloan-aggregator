//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../helpers.sol";

contract MakerImplementation is Helper {

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
        require((_route == 2 || _route == 3 || _route == 4), "invalid-MAKER-route");
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        if (_route == 2) {
            routeMaker(_tokens[0], _amounts[0], _data);
        } else if (_route == 3) {
            routeMakerCompound(_tokens, _amounts, _data);
        } else if (_route == 4) {
            routeMakerAave(_tokens, _amounts, _data);
        }
    }

    /**
     * @dev Fallback function for makerdao flashloan.
     * @notice Fallback function for makerdao flashloan.
     * @param _initiator initiator address for flashloan.
     * @param _amount DAI amount for flashloan.
     * @param _fee fee for the flashloan.
     * @param _data extra data passed(includes route info aswell).
     */
    function onFlashLoan(
        address _initiator,
        address,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external verifyDataHash(_data) returns (bytes32) {
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == address(makerLending), "not-maker-sender");

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
            calculateFeeBPS(route_, sender_)
        );

        if (route_ == 2) {
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
        } else if (route_ == 3 || route_ == 4) {
            require(_fee == 0, "flash-DAI-fee-not-0");

            address[] memory _daiTokenList = new address[](1);
            uint256[] memory _daiTokenAmountsList = new uint256[](1);
            _daiTokenList[0] = daiTokenAddr;
            _daiTokenAmountsList[0] = _amount;

            if (route_ == 3) {
                compoundSupply(_daiTokenList, _daiTokenAmountsList);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupply(_daiTokenList, _daiTokenAmountsList);
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

            if (route_ == 3) {
                compoundPayback(tokens_, amounts_);
                compoundWithdraw(_daiTokenList, _daiTokenAmountsList);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdraw(_daiTokenList, _daiTokenAmountsList);
            }
        } else {
            revert("wrong-route");
        }

        instaLoanVariables_._finBals = calculateBalances(
            tokens_,
            address(this)
        );
        validateFlashloan(instaLoanVariables_);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /**
     * @dev Middle function for route 2.
     * @notice Middle function for route 2.
     * @param _token token address for flashloan(DAI).
     * @param _amount DAI amount for flashloan.
     * @param _data extra data passed.
     */
    function routeMaker(
        address _token,
        uint256 _amount,
        bytes memory _data
    ) internal {
        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;
        bytes memory data_ = abi.encode(
            2,
            tokens_,
            amounts_,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            _token,
            _amount,
            data_
        );
    }

    /**
     * @dev Middle function for route 3.
     * @notice Middle function for route 3.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeMakerCompound(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            3,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            daiTokenAddr,
            daiBorrowAmount,
            data_
        );
    }

    /**
     * @dev Middle function for route 4.
     * @notice Middle function for route 4.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeMakerAave(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            4,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            daiTokenAddr,
            daiBorrowAmount,
            data_
        );
    }
}