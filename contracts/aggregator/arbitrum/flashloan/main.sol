//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {Helper} from "./helpers.sol";

import {TokenInterface, InstaFlashReceiverInterface} from "./interfaces.sol";

contract FlashAggregatorArbitrum is Helper {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );

    /**
     * @dev Fallback function for balancer flashloan.
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
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        if (_route == 1) {
            revert("this route is only for mainnet, polygon and avalanche");
        } else if (_route == 2) {
            revert("this route is only for mainnet");
        } else if (_route == 3) {
            revert("this route is only for mainnet");
        } else if (_route == 4) {
            revert("this route is only for mainnet");
        } else if (_route == 5) {
            routeBalancer(_tokens, _amounts, _data);
        } else if (_route == 6) {
            revert("this route is only for mainnet");
        } else if (_route == 7) {
            revert("this route is only for mainnet and polygon");
        } else {
            revert("route-does-not-exist");
        }

        emit LogFlashloan(msg.sender, _route, _tokens, _amounts);
    }

    /**
     * @dev Function to get the list of available routes.
     * @notice Function to get the list of available routes.
     */
    function getRoutes() public pure returns (uint16[] memory routes_) {
        routes_ = new uint16[](1);
        routes_[0] = 5;
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury.
     * @param _tokens token addresses for transferring fee to treasury.
     */
    function transferFeeToTreasury(address[] memory _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            uint256 decimals_ = TokenInterface(_tokens[i]).decimals();
            uint256 amtToSub_ = decimals_ == 18 ? 1e10 : decimals_ > 12
                ? 10000
                : decimals_ > 7
                ? 100
                : 10;
            uint256 amtToTransfer_ = token_.balanceOf(address(this)) > amtToSub_
                ? (token_.balanceOf(address(this)) - amtToSub_)
                : 0;
            if (amtToTransfer_ > 0)
                token_.safeTransfer(treasuryAddr, amtToTransfer_);
        }
    }
}

contract InstaFlashAggregatorArbitrum is FlashAggregatorArbitrum {
    /* 
     Deprecated
    */
    function initialize() public {
        require(status == 0, "cannot-call-again");
        status = 1;
    }

    receive() external payable {}
}
