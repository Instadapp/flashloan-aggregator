//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract FlashAggregatorPolygon is Helper {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );

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
        require(
            msg.sender == aaveV2LendingAddr || msg.sender == aaveV3LendingAddr,
            "not-aave-sender"
        );

        FlashloanVariables memory instaLoanVariables_;

        (uint256 route_, address sender_, bytes memory data_) = abi.decode(
            _data,
            (uint256, address, bytes)
        );

        instaLoanVariables_._tokens = _assets;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(route_)
        );
        instaLoanVariables_._iniBals = calculateBalances(
            _assets,
            address(this)
        );
        if (route_ == 1) {
            safeApprove(instaLoanVariables_, _premiums, aaveV2LendingAddr);
        } else if (route_ == 9) {
            safeApprove(instaLoanVariables_, _premiums, aaveV3LendingAddr);
        } else {
            revert("wrong-route");
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
                _assets,
                _amounts,
                instaLoanVariables_._instaFees,
                sender_,
                data_
            );
        }

        instaLoanVariables_._finBals = calculateBalances(
            _assets,
            address(this)
        );
        validateFlashloan(instaLoanVariables_);

        return true;
    }

    /**
     * @dev Callback function for balancer flashloan.
     * @notice Callback function for balancer flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _fees list of fees for the corresponding addresses for flashloan.
     * @param _data extra data passed(includes route info aswell).
     */
    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        bytes memory _data
    ) external verifyDataHash(_data) {
        require(msg.sender == balancerLendingAddr, "not-balancer-sender");

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
            calculateFeeBPS(route_)
        );

        if (route_ == 5) {
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
            safeTransferWithFee(
                instaLoanVariables_,
                _fees,
                balancerLendingAddr
            );
        } else if (route_ == 7) {
            require(_fees[0] == 0, "flash-ETH-fee-not-0");

            address[] memory wEthTokenList = new address[](1);
            wEthTokenList[0] = wEthToken;

            aaveSupply(wEthTokenList, _amounts);
            aaveBorrow(tokens_, amounts_);
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

            aavePayback(tokens_, amounts_);
            aaveWithdraw(wEthTokenList, _amounts);
            instaLoanVariables_._finBals = calculateBalances(
                tokens_,
                address(this)
            );
            validateFlashloan(instaLoanVariables_);
            instaLoanVariables_._amounts = _amounts;
            instaLoanVariables_._tokens = wEthTokenList;
            safeTransferWithFee(
                instaLoanVariables_,
                _fees,
                balancerLendingAddr
            );
        } else {
            revert("wrong-route");
        }
    }

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
    ) external verifyDataHash(data) {
        FlashloanVariables memory instaLoanVariables_;
        UniswapFlashInfo memory uniswapFlashData_;

        (
            instaLoanVariables_._tokens,
            instaLoanVariables_._amounts,
            uniswapFlashData_.sender,
            uniswapFlashData_.key,
            uniswapFlashData_.data
        ) = abi.decode(data, (address[], uint256[], address, PoolKey, bytes));

        address pool = computeAddress(
            uniswapFactoryAddr,
            uniswapFlashData_.key
        );
        require(msg.sender == pool, "invalid-sender");

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

        safeTransfer(instaLoanVariables_, uniswapFlashData_.sender);

        if (checkIfDsa(uniswapFlashData_.sender)) {
            Address.functionCall(
                uniswapFlashData_.sender,
                uniswapFlashData_.data,
                "DSA-flashloan-fallback-failed"
            );
        } else {
            InstaFlashReceiverInterface(uniswapFlashData_.sender)
                .executeOperation(
                    instaLoanVariables_._tokens,
                    instaLoanVariables_._amounts,
                    instaLoanVariables_._instaFees,
                    uniswapFlashData_.sender,
                    uniswapFlashData_.data
                );
        }

        instaLoanVariables_._finBals = calculateBalances(
            instaLoanVariables_._tokens,
            address(this)
        );

        validateFlashloan(instaLoanVariables_);

        uint256[] memory fees_;
        if (instaLoanVariables_._tokens.length == 2) {
            fees_ = new uint256[](2);
            fees_[0] = fee0;
            fees_[1] = fee1;
        } else if (
            instaLoanVariables_._tokens[0] == uniswapFlashData_.key.token0
        ) {
            fees_ = new uint256[](1);
            fees_[0] = fee0;
        } else {
            fees_ = new uint256[](1);
            fees_[0] = fee1;
        }
        safeTransferWithFee(instaLoanVariables_, fees_, msg.sender);
    }

    /**
     * @dev Middle function for route 1.
     * @notice Middle function for route 1.
     * @param _tokens list of token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _data extra data passed.
     */
    function routeAaveV2(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(1, msg.sender, _data);
        uint256 length_ = _tokens.length;
        uint256[] memory _modes = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            _modes[i] = 0;
        }
        dataHash = bytes32(keccak256(data_));
        aaveV2Lending.flashLoan(
            address(this),
            _tokens,
            _amounts,
            _modes,
            address(0),
            data_,
            3228
        );
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
        bytes memory data_ = abi.encode(9, msg.sender, _data);
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
            3228
        );
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
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for (uint256 i = 0; i < length_; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        bytes memory data_ = abi.encode(
            5,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            tokens_,
            _amounts,
            data_
        );
    }

    /**
     * @dev Middle function for route 7.
     * @notice Middle function for route 7.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeBalancerAave(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            7,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wEthToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            wethTokenList_,
            wethAmountList_,
            data_
        );
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
            revert("Number of tokens do not match");
        }

        IUniswapV3Pool pool = IUniswapV3Pool(
            computeAddress(uniswapFactoryAddr, key)
        );

        bytes memory data_ = abi.encode(
            _tokens,
            _amounts,
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
        bytes calldata _instadata
    ) external reentrancy {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        if (_route == 1) {
            routeAaveV2(_tokens, _amounts, _data);
        } else if (_route == 5) {
            routeBalancer(_tokens, _amounts, _data);
        } else if (_route == 7) {
            routeBalancerAave(_tokens, _amounts, _data);
        } else if (_route == 8) {
            routeUniswap(_tokens, _amounts, _data, _instadata);
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
        routes_ = new uint16[](5);
        routes_[0] = 1;
        routes_[1] = 5;
        routes_[2] = 7;
        routes_[3] = 8;
        routes_[4] = 9;
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
    // function initialize() public {
    //     require(status == 0, "cannot-call-again");
    //     status = 1;
    // }

    receive() external payable {}
}
