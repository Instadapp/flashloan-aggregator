//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {Helper} from "./helpers.sol";

import {TokenInterface, InstaFlashReceiverInterface, IUniswapV3Pool} from "./interfaces.sol";

contract FlashAggregatorOptimism is Helper {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );

    struct UniswapInfo {
        uint256 amount0;
        uint256 amount1;
        address sender_;
        PoolKey key;
        bytes data;
    }

    /**
     * @dev Callback function for uniswap flashloan.
     * @notice Callback function for uniswap flashloan.
     * @param fee0 The fee from calling flash for token0
     * @param fee1 The fee from calling flash for token1
     * @param data extra data passed(includes route info aswell).
     */
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes memory data
    ) external verifyDataHash(data) {
        UniswapInfo memory uniswapFlashData_;

        (
            uniswapFlashData_.amount0,
            uniswapFlashData_.amount1,
            uniswapFlashData_.sender_,
            uniswapFlashData_.key,
            uniswapFlashData_.data
        ) = abi.decode(data, (uint256, uint256, address, PoolKey, bytes));

        address pool = computeAddress(factory, uniswapFlashData_.key);
        require(msg.sender == pool, "invalid-sender");

        FlashloanVariables memory instaLoanVariables_;
        instaLoanVariables_._amounts = new uint256[](2);
        instaLoanVariables_._tokens = new address[](2);
        instaLoanVariables_._tokens[0] = uniswapFlashData_.key.token0;
        instaLoanVariables_._tokens[1] = uniswapFlashData_.key.token1;
        instaLoanVariables_._amounts[0] = uniswapFlashData_.amount0;
        instaLoanVariables_._amounts[1] = uniswapFlashData_.amount1;

        instaLoanVariables_._iniBals = calculateBalances(
            instaLoanVariables_._tokens,
            address(this)
        );

        uint256 feeBPS = uint256(uniswapFlashData_.key.fee / 100);
        if (feeBPS < InstaFeeBPS) {
            feeBPS = InstaFeeBPS;
        }

        instaLoanVariables_._instaFees = calculateFees(
            instaLoanVariables_._amounts,
            feeBPS
        );

        safeTransfer(instaLoanVariables_, uniswapFlashData_.sender_);

        if (checkIfDsa(uniswapFlashData_.sender_)) {
            Address.functionCall(
                uniswapFlashData_.sender_,
                uniswapFlashData_.data,
                "DSA-flashloan-fallback-failed"
            );
        } else {
            InstaFlashReceiverInterface(uniswapFlashData_.sender_)
                .executeOperation(
                    instaLoanVariables_._tokens,
                    instaLoanVariables_._amounts,
                    instaLoanVariables_._instaFees,
                    uniswapFlashData_.sender_,
                    uniswapFlashData_.data
                );
        }

        instaLoanVariables_._finBals = calculateBalances(
            instaLoanVariables_._tokens,
            address(this)
        );

        validateFlashloan(instaLoanVariables_);

        uint256[] memory fees_ = new uint256[](2);
        fees_[0] = fee0;
        fees_[1] = fee1;
        safeTransferWithFee(instaLoanVariables_, fees_, msg.sender);
    }

    /**
     * @dev Middle function for route 8.
     * @notice Middle function for route 8.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     * @param _instadata pool key encoded
     */
    function routeUniswap(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data,
        bytes memory _instadata
    ) internal {
        PoolKey memory key = abi.decode(_instadata, (PoolKey));

        uint256 amount0_;
        uint256 amount1_;

        if (_tokens.length == 1) {
            require(
                (_tokens[0] == key.token0 || _tokens[0] == key.token1),
                "tokens-do-not-match-pool"
            );
            if (_tokens[0] == key.token0) {
                amount0_ = _amounts[0];
            } else {
                amount1_ = _amounts[0];
            }
        } else if (_tokens.length == 2) {
            require(
                (_tokens[0] == key.token0 && _tokens[1] == key.token1),
                "tokens-do-not-match-pool"
            );
            amount0_ = _amounts[0];
            amount1_ = _amounts[1];
        } else {
            revert("Number of tokens does not match");
        }

        IUniswapV3Pool pool = IUniswapV3Pool(computeAddress(factory, key));

        bytes memory data_ = abi.encode(
            amount0_,
            amount1_,
            msg.sender,
            key,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        pool.flash(address(this), amount0_, amount1_, data_);
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
        bytes calldata _instadata // kept for future use by instadapp. Currently not used anywhere.
    ) external reentrancy {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        if (_route == 8) {
            routeUniswap(_tokens, _amounts, _data, _instadata);
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
        routes_[0] = 8;
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

contract InstaFlashAggregatorOptimism is FlashAggregatorOptimism {
    /* 
     Deprecated
    */
    function initialize() public {
        require(status == 0, "cannot-call-again");
        status = 1;
    }

    receive() external payable {}
}
