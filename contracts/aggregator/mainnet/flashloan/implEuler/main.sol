//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../helpers.sol";

contract EulerImplementation is Helper {

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
        require(_route == 10, "invalid-EULER-route");
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);
        routeEuler(_tokens[0], _amounts[0], _data);
    }

    function onFlashLoan(
        address _initiator,
        address,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external verifyDataHash(_data) returns (bytes32) {
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == address(eulerLending), "not-maker-sender");

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

        instaLoanVariables_._finBals = calculateBalances(
            tokens_,
            address(this)
        );
        validateFlashloan(instaLoanVariables_);

        TokenInterface(tokens_[0]).approve(address(eulerLending), amounts_[0]);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function routeEuler(
        address _token,
        uint256 _amount,
        bytes memory _data
    ) internal {

        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;
        bytes memory data_ = abi.encode(
            10,
            tokens_,
            amounts_,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        eulerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            _token,
            _amount,
            data_
        );
    }
}
