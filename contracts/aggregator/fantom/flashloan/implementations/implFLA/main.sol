//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../../helper.sol";

contract FLAImplementationFantom is Helper {
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
        require(_route == 10, "invalid-FLA-route");
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);
        routeFLA(msg.sender, _tokens, _amounts, _data);
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
        if (_route == 10) {
            BPS_ = InstaFeeBPS;
        } else {
            revert("Invalid source");
        }
    }

    function routeFLA(
        address _receiverAddress,
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal returns (bool) {
        FlashloanVariables memory instaLoanVariables_;
        instaLoanVariables_._tokens = _tokens;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(10)
        );
        instaLoanVariables_._iniBals = calculateBalances(
            _tokens,
            address(this)
        );

        safeTransfer(instaLoanVariables_, _receiverAddress);

        if (checkIfDsa(_receiverAddress)) {
            Address.functionCall(
                _receiverAddress,
                _data,
                "DSA-flashloan-fallback-failed"
            );
        } else {
            require(
                InstaFlashReceiverInterface(_receiverAddress).executeOperation(
                    _tokens,
                    _amounts,
                    instaLoanVariables_._instaFees,
                    _receiverAddress,
                    _data
                ),
                "invalid flashloan execution"
            );
        }

        instaLoanVariables_._finBals = calculateBalances(
            _tokens,
            address(this)
        );

        validateFlashloan(instaLoanVariables_);

        status = 1;
        return true;
    }
}
