//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract FlashAggregatorBSC is Helper {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );

    struct PancakeSwapFlashInfo {
        address sender;
        address pairAddr;
        bytes data;
    }

    /**
     * @dev Callback function for PancakeSwap flashloan.
     * @notice Callback function for PancakeSwap flashloan.
     * @param sender The address that initiated the swap on PancakeSwap
     * @param amount0 The amount of token0 that was borrowed
     * @param amount1 The amount of token1 that was borrowed
     * @param data Extra data passed (includes route info as well)
     */
    function pancakeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        FlashloanVariables memory instaLoanVariables_;
        PancakeSwapFlashInfo memory pancakeSwapInfo_;
        (
            instaLoanVariables_._tokens,
            instaLoanVariables_._amounts,
            pancakeSwapInfo_.sender,
            pancakeSwapInfo_.pairAddr,
            pancakeSwapInfo_.data
        ) = abi.decode(data, (address[], uint256[], address, address, bytes));

        require(msg.sender == pancakeSwapInfo_.pairAddr, "invalid-sender");
        instaLoanVariables_._iniBals = calculateBalances(
            instaLoanVariables_._tokens,
            address(this)
        );

        uint256 feeBPS = 25; // fixed Pancake swap fee BPS
        if (feeBPS < InstaFeeBPS) {
            feeBPS = InstaFeeBPS;
        }

        instaLoanVariables_._instaFees = calculateFees(
            instaLoanVariables_._amounts,
            feeBPS
        );

        safeTransfer(instaLoanVariables_, pancakeSwapInfo_.sender);

        InstaFlashReceiverInterface(pancakeSwapInfo_.sender)
            .executeOperation(
                instaLoanVariables_._tokens,
                instaLoanVariables_._amounts,
                instaLoanVariables_._instaFees,
                pancakeSwapInfo_.sender,
                pancakeSwapInfo_.data
            );
        
        instaLoanVariables_._finBals = calculateBalances(
            instaLoanVariables_._tokens,
            address(this)
        );

        validateFlashloan(instaLoanVariables_);

        // Use the already calculated fees (which include PancakeSwap's 25 BPS)
        safeTransferWithFee(instaLoanVariables_, instaLoanVariables_._instaFees, msg.sender);
    }

    /**
     * @dev Callback function for aave flashloan.
     * @notice Callback function for aave flashloan.
     * @param _assets list of asset addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets for flashloan.
     * @param _premiums list of premiums/fees for the corresponding addresses for flashloan.
     * @param _initiator initiator address for flashloan.
     * @param _data extra data passed.
     */
    function executeOperation(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _premiums,
        address _initiator,
        bytes memory _data
    ) external verifyDataHash(_data) returns (bool) {
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == aaveV3LendingAddr, "not-aave-sender");

        FlashloanVariables memory instaLoanVariables_;

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );

        instaLoanVariables_._tokens = _assets;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(9)
        );
        for (uint256 i = 0; i < _amounts.length; i++) {
            if (instaLoanVariables_._instaFees[i] < _premiums[i]) {
                instaLoanVariables_._instaFees[i] = _premiums[i];
            }
        }
        instaLoanVariables_._iniBals = calculateBalances(
            _assets,
            address(this)
        );

        safeApprove(instaLoanVariables_, _premiums, aaveV3LendingAddr);
        safeTransfer(instaLoanVariables_, sender_);

        InstaFlashReceiverInterface(sender_).executeOperation(
            _assets,
            _amounts,
            instaLoanVariables_._instaFees,
            sender_,
            data_
        );
        
        instaLoanVariables_._finBals = calculateBalances(
            _assets,
            address(this)
        );
        validateFlashloan(instaLoanVariables_);

        return true;
    }
   
    function routePancakeSwap(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data,
        bytes memory _instadata
    ) internal {
        address pairAddr = abi.decode(_instadata, (address));
        IPancakePair pair = IPancakePair(pairAddr);

        uint256 amount0_;
        uint256 amount1_;

        address pairToken0 = pair.token0();
        address pairToken1 = pair.token1();

        if (_tokens.length == 1) {
            require(
                (_tokens[0] == pairToken0 || _tokens[0] == pairToken1),
                "tokens-do-not-match-pool"
            );
            if (_tokens[0] == pairToken0) {
                amount0_ = _amounts[0];
            } else {
                amount1_ = _amounts[0];
            }
        } else if (_tokens.length == 2) {
            require(
                (_tokens[0] == pairToken0 && _tokens[1] == pairToken1),
                "tokens-do-not-match-pool"
            );
            amount0_ = _amounts[0];
            amount1_ = _amounts[1];
        } else {
            revert("Number of tokens do not match");
        }

        bytes memory data_ = abi.encode(
            _tokens,
            _amounts,
            msg.sender,
            pairAddr,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        pair.swap(amount0_, amount1_, address(this), data_);
    }

    /**
     * @dev Middle function for route 9.
     * @notice Middle function for route 9.
     * @param _tokens list of token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _data extra data passed.
     */
    function routeAaveV3(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(msg.sender, _data);
        uint256 length_ = _tokens.length;
        uint256[] memory _modes = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            _modes[i] = 0;
        }
        dataHash = bytes32(keccak256(data_));
        aaveV3Lending.flashLoan(
            address(this),
            _tokens,
            _amounts,
            _modes,
            address(0),
            data_,
            0
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
        bytes calldata _instadata
    ) external reentrancy {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        if (_route == 12) {
            routePancakeSwap(_tokens, _amounts, _data, _instadata);
        } else if (_route == 9) {
            routeAaveV3(_tokens, _amounts, _data);
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
        routes_ = new uint16[](2);
        routes_[0] = 12; // PancakeSwap
        routes_[1] = 9; // Aave V3
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

contract InstaFlashAggregatorBSC is FlashAggregatorBSC {
    function initialize() public {
        require(status == 0, "cannot-call-again");
        status = 1;
    }

    receive() external payable {}
}
