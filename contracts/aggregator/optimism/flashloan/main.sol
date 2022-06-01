//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract FlashAggregatorOptimism is Helper {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );

    struct UniswapFlashInfo {
        address sender;
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
    ) external {
        spell(UNISWAP_IMPL, msg.data);
    }

    function routeFLA(
        address _receiverAddress,
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal reentrancy returns (bool) {//TODO: doubt

        FlashloanVariables memory instaLoanVariables_;
        instaLoanVariables_._tokens = _tokens;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(9)
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
            require(InstaFlashReceiverInterface(_receiverAddress).executeOperation(
                _tokens,
                _amounts,
                instaLoanVariables_._instaFees,
                _receiverAddress,
                _data
            ), "invalid flashloan execution");
        }

        instaLoanVariables_._finBals = calculateBalances(
            _tokens,
            address(this)
        );
        validateFlashloan(instaLoanVariables_);

        status = 1;
        return true;
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
        bytes calldata _instadata
    ) external {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");
        if (_route == 8) {
            spell(UNISWAP_IMPL, msg.data);
        } else if (_route == 9) {
            (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
            validateTokens(_tokens);
            routeFLA(msg.sender, _tokens, _amounts, _data);
        }

        emit LogFlashloan(msg.sender, _route, _tokens, _amounts);
    }

    /**
     * @dev Function to get the list of available routes.
     * @notice Function to get the list of available routes.
     */
    function getRoutes() public pure returns (uint16[] memory routes_) {
        routes_ = new uint16[](2);
        routes_[0] = 8;
        routes_[1] = 9;
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
    // function initialize() public {
    //     require(status == 0, "cannot-call-again");
    //     status = 1;
    // }

    /**
     * @dev Function created for testing upgradable implementations
     */
    // function initialize(address uniswap) public {
    //     UNISWAP_IMPL = uniswap;
    // }

    receive() external payable {}
}
