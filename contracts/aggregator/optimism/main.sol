//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";

import {Helper} from "./helpers.sol";

import {TokenInterface, InstaFlashReceiverInterface, IUniswapV3Pool} from "./interfaces.sol";

contract FlashAggregatorPolygon is Helper {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );

    struct info {
        uint256 amount0;
        uint256 amount1;
        address sender_;
        PoolKey key;
    }

    struct para {
        uint256 fee0;
        uint256 fee1;
        bytes data;
    }

    /// @param fee0 The fee from calling flash for token0
    /// @param fee1 The fee from calling flash for token1
    /// @param data The data needed in the callback passed as FlashCallbackData from `initFlash`
    /// @notice implements the callback called from flash
    /// @dev fails if the flash is not profitable, meaning the amountOut from the flash is less than the amount borrowed
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes memory data
    ) external verifyDataHash(data) {
        info memory _data;
        para memory _para;

        _para.fee0 = fee0;
        _para.fee1 = fee1;
        _para.data = data;

        (_data.amount0, _data.amount1, _data.sender_, _data.key) = abi.decode(
            data,
            (uint256, uint256, address, PoolKey)
        );

        address pool = computeAddress(factory, _data.key);
        require(msg.sender == pool, "Invalid sender");

        address token0 = _data.key.token0;
        address token1 = _data.key.token1;

        FlashloanVariables memory instaLoanVariables_;

        uint256[] memory amounts_ = new uint256[](2);
        address[] memory tokens_ = new address[](2);
        uint256[] memory fees_ = new uint256[](2);

        amounts_[0] = _data.amount0;
        tokens_[0] = token0;
        amounts_[1] = _data.amount1;
        tokens_[1] = token1;
        fees_[0] = _para.fee0;
        fees_[1] = _para.fee1;

        instaLoanVariables_._tokens = tokens_;
        instaLoanVariables_._amounts = amounts_;
        instaLoanVariables_._iniBals = calculateBalances(
            tokens_,
            address(this)
        );

        instaLoanVariables_._instaFees = calculateFees(
            amounts_,
            uint256(_data.key.fee / 100)
        );

        safeTransfer(instaLoanVariables_, _data.sender_);

        if (checkIfDsa(_data.sender_)) {
            Address.functionCall(
                _data.sender_,
                _para.data,
                "DSA-flashloan-fallback-failed"
            );
        } else {
            InstaFlashReceiverInterface(_data.sender_).executeOperation(
                tokens_,
                amounts_,
                instaLoanVariables_._instaFees,
                _data.sender_,
                _para.data
            );
        }

        instaLoanVariables_._finBals = calculateBalances(
            tokens_,
            address(this)
        );

        validateFlashloan(instaLoanVariables_);

        safeApprove(instaLoanVariables_, fees_, msg.sender);
        safeTransferWithFee(instaLoanVariables_, fees_, msg.sender);
    }

    /**
     * @dev Middle function for route 8.
     * @notice Middle function for route 8.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     *@param _instadata pool key encoded
     */
    function routeUniswap(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data,
        bytes memory _instadata
    ) internal {
        PoolKey memory key = abi.decode(_instadata, (PoolKey));

        uint256 length_ = _tokens.length;
        uint256[] memory amounts_ = new uint256[](2);

        if (length_ == 1) {
            require(
                (_tokens[0] == key.token0 || _tokens[0] == key.token1),
                "Tokens does not match pool"
            );
            if (_tokens[0] == key.token0) {
                amounts_[0] = _amounts[0];
                amounts_[1] = 0;
            } else {
                amounts_[0] = 0;
                amounts_[1] = _amounts[0];
            }
        } else if (length_ == 2) {
            require(
                (_tokens[0] == key.token0 && _tokens[1] == key.token1),
                "Tokens does not match pool"
            );
            amounts_[0] = _amounts[0];
            amounts_[1] = _amounts[1];
        } else {
            revert("Number of tokens does not match");
        }

        IUniswapV3Pool pool = IUniswapV3Pool(computeAddress(factory, key));

        bytes memory data_ = abi.encode(
            amounts_[0],
            amounts_[1],
            msg.sender,
            key,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        pool.flash(address(this), amounts_[0], amounts_[1], data_);
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

contract InstaFlashAggregatorPolygon is FlashAggregatorPolygon {
    /* 
     Deprecated
    */
    function initialize() public {
        require(status == 0, "cannot-call-again");
        status = 1;
    }

    receive() external payable {}
}
