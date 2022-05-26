//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../helpers.sol";

import "hardhat/console.sol";

contract EquilizerImplementation is Helper {

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
        console.log("Entered Equilizer flashloan");
        require(_route == 9, "invalid-EQUILIZER-route");
        require(_tokens.length == 1, "provide-one-token-array");//TODO: review
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);
        routeEquilizer(_tokens, _amounts, _data);
    }

    /**
     * @dev Middle function for route 2.
     * @notice Middle function for route 2.
     * @param _tokens token address for flashloan.
     * @param _amounts DAI amount for flashloan.
     * @param _data extra data passed.
     */
    function routeEquilizer(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        console.log("Entered route equilizer");
        bytes memory data_ = abi.encode(
            9,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        console.log("token: ", _tokens[0], " , amount: ", _amounts[0]);
        equilizerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            _tokens[0],
            _amounts[0],
            data_
        );
        console.log("balance of this address: ", IERC20(_tokens[0]).balanceOf(address(this)));
    }

    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external verifyDataHash(_data) returns (bytes32) {
        console.log("Entered callback Equilizer");
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == address(equilizerLending), "not-equilizer-sender");

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
            calculateFeeBPS(route_, sender_, tokens_[0], amounts_[0])
        );
        console.log("_instaFees: ", instaLoanVariables_._instaFees[0]);

        if (route_ == 9) {
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
}