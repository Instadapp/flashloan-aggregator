//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../helpers.sol";

contract BalancerImplementationArbitrum is Helper {

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
        bytes memory _instadata
    ) external reentrancy {
        require(_route == 5 , "invalid-BALANCER-route");
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);
        routeBalancer(_tokens, _amounts, _data);
    }

    /**
     * @dev Callback function for balancer flashloan.
     * @notice Fallback function for balancer flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _fees list of fees for the corresponding addresses for flashloan.
     * @param _data extra data passed.
     */
    function receiveFlashLoan(
        IERC20[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        bytes memory _data
    ) external verifyDataHash(_data) {
        require(msg.sender == balancerLendingAddr, "not-balancer-sender");

        FlashloanVariables memory instaLoanVariables_;

        uint256 length_ = _tokens.length;
        instaLoanVariables_._tokens = new address[](length_);
        for (uint256 i = 0; i < length_; i++) {
            instaLoanVariables_._tokens[i] = address(_tokens[i]);
        }

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );

        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._iniBals = calculateBalances(
            instaLoanVariables_._tokens,
            address(this)
        );
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(5)
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
                instaLoanVariables_._tokens,
                _amounts,
                instaLoanVariables_._instaFees,
                sender_,
                data_
            );
        }

        instaLoanVariables_._finBals = calculateBalances(
            instaLoanVariables_._tokens,
            address(this)
        );
        validateFlashloan(instaLoanVariables_);

        safeTransferWithFee(instaLoanVariables_, _fees, balancerLendingAddr);
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
        bytes memory data_ = abi.encode(msg.sender, _data);
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for (uint256 i = 0; i < length_; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            tokens_,
            _amounts,
            data_
        );
    }
}
