//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Flashloan.
 * @dev Flashloan aggregator.
 */

import "./helpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AdminModule is Helper {
    event updateOwnerLog(address indexed oldOwner, address indexed newOwner);

    event updateWhitelistLog(
        address indexed account,
        bool indexed isWhitelisted_
    );

    /**
     * @dev owner gaurd.
     * @notice owner gaurd.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "not-owner");
        _;
    }

    /**
     * @dev Update owner.
     * @notice Update owner.
     * @param newOwner_ address of new owner.
     */
    function updateOwner(address newOwner_) external onlyOwner {
        address oldOwner_ = owner;
        owner = newOwner_;
        emit updateOwnerLog(oldOwner_, newOwner_);
    }

    /**
     * @dev Update whitelist.
     * @notice Update whitelist.
     * @param account_ address to update the whitelist for.
     * @param whitelist_ want to whitelist -> true, else false.
     */
    function updateWhitelist(address account_, bool whitelist_)
        external
        onlyOwner
    {
        isWhitelisted[account_] = whitelist_;
        emit updateWhitelistLog(account_, whitelist_);
    }
}

contract Setups is AdminModule {
    using SafeERC20 for IERC20;

    /**
     * @dev Add to token to cToken mapping.
     * @notice Add to token to cToken mapping.
     * @param _cTokens list of cToken addresses to be added to the mapping.
     */
    function addTokenToCToken(address[] memory _cTokens) public {
        for (uint256 i = 0; i < _cTokens.length; i++) {
            (bool isMarket_, , ) = troller.markets(_cTokens[i]);
            require(isMarket_, "unvalid-ctoken");
            address token_ = CTokenInterface(_cTokens[i]).underlying();
            require(tokenToCToken[token_] == address((0)), "already-added");
            tokenToCToken[token_] = _cTokens[i];
            IERC20(token_).safeApprove(_cTokens[i], type(uint256).max);
        }
    }
}

contract FlashAggregator is Setups {
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
            msg.sender == aaveV2LendingAddr || msg.sender == aaveV3LendingAddr || msg.sender == sparkLendingAddr,
            "not-aave-sender"
        );

        FlashloanVariables memory instaLoanVariables_;
        DataHelper memory helper;

        (
            helper.route_,
            helper.tokens_,
            helper.amounts_,
            helper.sender_,
            helper.data_
        ) = abi.decode(_data, (uint256, address[], uint256[], address, bytes));

        instaLoanVariables_._tokens = helper.tokens_;
        instaLoanVariables_._amounts = helper.amounts_;
        instaLoanVariables_._instaFees = calculateFees(
            helper.amounts_,
            calculateFeeBPS(helper.route_, helper.sender_)
        );

        for (uint i; i < _assets.length; i++) {
            if (helper.route_ == 1) {
                approve(_assets[i], aaveV2LendingAddr, _amounts[i] + _premiums[i]);
            } else if (helper.route_ == 9) {
                approve(_assets[i], aaveV3LendingAddr, _amounts[i] + _premiums[i]);
            } else if (helper.route_ == 10) {
                approve(_assets[i], sparkLendingAddr, _amounts[i] + _premiums[i]);
            } else {
                revert("wrong-route");
            }
        }

        if (helper.route_ == 9 || helper.route_ == 10) {
            if (helper.tokens_[0] == stEthTokenAddr) {
                wstEthToken.unwrap(_amounts[0]);
            }
        }

        instaLoanVariables_._iniBals = calculateBalances(
            helper.tokens_,
            address(this)
        );

        safeTransfer(instaLoanVariables_, helper.sender_);

        if (checkIfDsa(helper.sender_)) {
            Address.functionCall(
                helper.sender_,
                helper.data_,
                "DSA-flashloan-fallback-failed"
            );
        } else {
            InstaFlashReceiverInterface(helper.sender_).executeOperation(
                helper.tokens_,
                helper.amounts_,
                instaLoanVariables_._instaFees,
                helper.sender_,
                helper.data_
            );
        }

        instaLoanVariables_._finBals = calculateBalances(
            helper.tokens_,
            address(this)
        );

        if (helper.route_ == 9 || helper.route_ == 10) {
            if (helper.tokens_[0] == stEthTokenAddr) {
                instaLoanVariables_._finBals[0] = instaLoanVariables_._finBals[0] + 10; // Taking 10 wei extra buffer for steth
                wstEthToken.wrap(helper.amounts_[0]);
            }
        }
        
        validateFlashloan(instaLoanVariables_);

        return true;
    }

    /**
     * @dev Fallback function for makerdao flashloan.
     * @notice Fallback function for makerdao flashloan.
     * @param _initiator initiator address for flashloan.
     * @param _amount DAI amount for flashloan.
     * @param _fee fee for the flashloan.
     * @param _data extra data passed(includes route info aswell).
     */
    function onFlashLoan(
        address _initiator,
        address,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external verifyDataHash(_data) returns (bytes32) {
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == address(makerLending), "not-maker-sender");

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

        if (route_ == 2) {
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
        } else if (route_ == 3 || route_ == 4) {
            require(_fee == 0, "flash-DAI-fee-not-0");

            address[] memory _daiTokenList = new address[](1);
            uint256[] memory _daiTokenAmountsList = new uint256[](1);
            _daiTokenList[0] = daiTokenAddr;
            _daiTokenAmountsList[0] = _amount;

            if (route_ == 3) {
                spell(
                    ADVANCED_ROUTES_IMPL,
                    abi.encodeWithSignature(
                        "compoundSupplyAndBorrow(address[],uint256[],address[],uint256[])",
                        _daiTokenList,
                        _daiTokenAmountsList,
                        tokens_,
                        amounts_
                    )
                );
            } else {
                spell(
                    ADVANCED_ROUTES_IMPL,
                    abi.encodeWithSignature(
                        "aaveSupplyAndBorrow(address[],uint256[],address[],uint256[])",
                        _daiTokenList,
                        _daiTokenAmountsList,
                        tokens_,
                        amounts_
                    )
                );
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
                    tokens_,
                    amounts_,
                    instaLoanVariables_._instaFees,
                    sender_,
                    data_
                );
            }

            if (route_ == 3) {
                spell(
                    ADVANCED_ROUTES_IMPL,
                    abi.encodeWithSignature(
                        "compoundPaybackAndWithdraw(address[],uint256[],address[],uint256[])",
                        tokens_,
                        amounts_,
                        _daiTokenList,
                        _daiTokenAmountsList
                    )
                );
            } else {
                spell(
                    ADVANCED_ROUTES_IMPL,
                    abi.encodeWithSignature(
                        "aavePaybackAndWithdraw(address[],uint256[],address[],uint256[])",
                        tokens_,
                        amounts_,
                        _daiTokenList,
                        _daiTokenAmountsList
                    )
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

    struct DataHelper {
        uint256 route_;
        address[] tokens_;
        uint256[] amounts_;
        address sender_;
        bytes data_;
    }

    /**
     * @dev Fallback function for balancer flashloan.
     * @notice Fallback function for balancer flashloan.
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
        require(msg.sender == address(balancerLending), "not-balancer-sender");

        FlashloanVariables memory instaLoanVariables_;
        DataHelper memory helper;

        (
            helper.route_,
            helper.tokens_,
            helper.amounts_,
            helper.sender_,
            helper.data_
        ) = abi.decode(_data, (uint256, address[], uint256[], address, bytes));

        instaLoanVariables_._tokens = helper.tokens_;
        instaLoanVariables_._amounts = helper.amounts_;
        instaLoanVariables_._iniBals = calculateBalances(
            helper.tokens_,
            address(this)
        );
        instaLoanVariables_._instaFees = calculateFees(
            helper.amounts_,
            calculateFeeBPS(helper.route_, helper.sender_)
        );

        if (helper.route_ == 5) {
            if (helper.tokens_[0] == stEthTokenAddr) {
                wstEthToken.unwrap(_amounts[0]);
            }
            safeTransfer(instaLoanVariables_, helper.sender_);
            if (checkIfDsa(helper.sender_)) {
                Address.functionCall(
                    helper.sender_,
                    helper.data_,
                    "DSA-flashloan-fallback-failed"
                );
            } else {
                InstaFlashReceiverInterface(helper.sender_).executeOperation(
                    helper.tokens_,
                    helper.amounts_,
                    instaLoanVariables_._instaFees,
                    helper.sender_,
                    helper.data_
                );
            }
            if (helper.tokens_[0] == stEthTokenAddr) {
                wstEthToken.wrap(helper.amounts_[0]);
            }

            instaLoanVariables_._finBals = calculateBalances(
                helper.tokens_,
                address(this)
            );
            if (helper.tokens_[0] == stEthTokenAddr) {
                // adding 10 wei to avoid any possible decimal errors in final calculations
                instaLoanVariables_._finBals[0] =
                    instaLoanVariables_._finBals[0] +
                    10;
                instaLoanVariables_._tokens[0] = address(wstEthToken);
                instaLoanVariables_._amounts[0] = _amounts[0];
            }
            validateFlashloan(instaLoanVariables_);
            safeTransferWithFee(
                instaLoanVariables_,
                _fees,
                address(balancerLending)
            );
        } else if (helper.route_ == 6 || helper.route_ == 7) {
            require(_fees[0] == 0, "flash-ETH-fee-not-0");

            address[] memory wEthTokenList = new address[](1);
            wEthTokenList[0] = address(wethToken);

            if (helper.route_ == 6) {
                spell(
                    ADVANCED_ROUTES_IMPL,
                    abi.encodeWithSignature(
                        "compoundSupplyAndBorrow(address[],uint256[],address[],uint256[])",
                        wEthTokenList,
                        _amounts,
                        helper.tokens_,
                        helper.amounts_
                    )
                );
            } else {
                 spell(
                    ADVANCED_ROUTES_IMPL,
                    abi.encodeWithSignature(
                        "aaveSupplyAndBorrow(address[],uint256[],address[],uint256[])",
                        wEthTokenList,
                        _amounts,
                        helper.tokens_,
                        helper.amounts_
                    )
                );
            }

            safeTransfer(instaLoanVariables_, helper.sender_);

            if (checkIfDsa(helper.sender_)) {
                Address.functionCall(
                    helper.sender_,
                    helper.data_,
                    "DSA-flashloan-fallback-failed"
                );
            } else {
                InstaFlashReceiverInterface(helper.sender_).executeOperation(
                    helper.tokens_,
                    helper.amounts_,
                    instaLoanVariables_._instaFees,
                    helper.sender_,
                    helper.data_
                );
            }

            if (helper.route_ == 6) {
                spell(
                    ADVANCED_ROUTES_IMPL,
                    abi.encodeWithSignature(
                        "compoundPaybackAndWithdraw(address[],uint256[],address[],uint256[])",
                        helper.tokens_,
                        helper.amounts_,
                        wEthTokenList,
                        _amounts
                    )
                );
            } else {
                spell(
                    ADVANCED_ROUTES_IMPL,
                    abi.encodeWithSignature(
                        "aavePaybackAndWithdraw(address[],uint256[],address[],uint256[])",
                        helper.tokens_,
                        helper.amounts_,
                        wEthTokenList,
                        _amounts
                    )
                );
            }
            instaLoanVariables_._finBals = calculateBalances(
                helper.tokens_,
                address(this)
            );
            validateFlashloan(instaLoanVariables_);
            instaLoanVariables_._tokens = wEthTokenList;
            instaLoanVariables_._amounts = _amounts;
            safeTransferWithFee(
                instaLoanVariables_,
                _fees,
                address(balancerLending)
            );
        } else {
            revert("wrong-route");
        }
    }

    // Fallback function for morpho route
    function onMorphoFlashLoan(
        uint256 _assets,
        bytes calldata _data
    ) external verifyDataHash(_data) returns (bool) {
        require(msg.sender == address(morpho), "not-morpho-sender");

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

        if (route_ == 11){
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

        // Final approval to transfer tokens to MORPHO
        IERC20(tokens_[0]).approve(address(morpho), _assets);

        return true;
    }

    /**
     * @dev Middle function for route 1, 9 and 10.
     * @notice Middle function for route 1, 9 and 10.
     * @param _tokens list of token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _data extra data passed.
     */
    function routeAaveAndSpark(
        uint256 route,
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            route,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        uint256 length_ = _tokens.length;
        uint256[] memory _modes = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            _modes[i] = 0;
        }
        dataHash = bytes32(keccak256(data_));

        if (route == 1) {
            aaveV2Lending.flashLoan(
                address(this),
                _tokens,
                _amounts,
                _modes,
                address(0),
                data_,
                3228
            );
        } else if (route == 9) {
            if (_tokens[0] == stEthTokenAddr) {
                require(length_ == 1, "steth-length-should-be-1");
                _tokens[0] = address(wstEthToken);
                _amounts[0] = wstEthToken.getWstETHByStETH(_amounts[0]);
            }
            aaveV3Lending.flashLoan(
                address(this),
                _tokens,
                _amounts,
                _modes,
                address(0),
                data_,
                3228
            );
        } else if (route == 10) {
            if (_tokens[0] == stEthTokenAddr) {
                require(length_ == 1, "steth-length-should-be-1");
                _tokens[0] = address(wstEthToken);
                _amounts[0] = wstEthToken.getWstETHByStETH(_amounts[0]);
            }
            sparkLending.flashLoan(
                address(this),
                _tokens,
                _amounts,
                _modes,
                address(0),
                data_,
                3228
            );
        }
    }

    /**
     * @dev Middle function for route 2.
     * @notice Middle function for route 2.
     * @param _token token address for flashloan(DAI).
     * @param _amount DAI amount for flashloan.
     * @param _data extra data passed.
     */
    function routeMaker(
        address _token,
        uint256 _amount,
        bytes memory _data
    ) internal {
        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;

        bytes memory data_ = abi.encode(
            2,
            tokens_,
            amounts_,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            _token,
            _amount,
            data_
        );
    }

    /**
     * @dev Middle function for route 3.
     * @notice Middle function for route 3.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeMakerCompound(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            3,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            daiTokenAddr,
            daiBorrowAmount,
            data_
        );
    }

    /**
     * @dev Middle function for route 4.
     * @notice Middle function for route 4.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeMakerAave(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            4,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            daiTokenAddr,
            daiBorrowAmount,
            data_
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
        if (_tokens[0] == stEthTokenAddr) {
            require(length_ == 1, "steth-length-should-be-1");
            tokens_[0] = IERC20(address(wstEthToken));
            _amounts[0] = wstEthToken.getWstETHByStETH(_amounts[0]);
        }
        balancerLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
            tokens_,
            _amounts,
            data_
        );
    }

    /**
     * @dev Middle function for route 6.
     * @notice Middle function for route 6.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeBalancerCompound(
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        bytes memory data_ = abi.encode(
            6,
            _tokens,
            _amounts,
            msg.sender,
            _data
        );
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wethToken);
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
     * @dev Middle function for route 7.
     * @notice Middle helper function for route 7.
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
        wethTokenList_[0] = wethToken;
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
     * @dev Middle function for route 11.
     * @notice Middle function for route 11.
     * @param _token token addresses for flashloan.
     * @param _amount list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function routeMorpho(
        address _token,
        uint256 _amount,
        bytes memory _data
    ) internal {
        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;
        bytes memory data_ = abi.encode(
            11,
            tokens_,
            amounts_,
            msg.sender,
            _data
        );
        dataHash = bytes32(keccak256(data_));
        morpho.flashLoan(
            _token,
            _amount,
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
            routeAaveAndSpark(1, _tokens, _amounts, _data);
        } else if (_route == 2) {
            routeMaker(_tokens[0], _amounts[0], _data);
        } else if (_route == 3) {
            routeMakerCompound(_tokens, _amounts, _data);
        } else if (_route == 4) {
            routeMakerAave(_tokens, _amounts, _data);
        } else if (_route == 5) {
            routeBalancer(_tokens, _amounts, _data);
        } else if (_route == 6) {
            routeBalancerCompound(_tokens, _amounts, _data);
        } else if (_route == 7) {
            routeBalancerAave(_tokens, _amounts, _data);
        } else if (_route == 9) {
            routeAaveAndSpark(9, _tokens, _amounts, _data);
        } else if (_route == 10) {
            routeAaveAndSpark(10, _tokens, _amounts, _data);
        } else if (_route == 11) {
            routeMorpho(_tokens[0], _amounts[0], _data);
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
        routes_ = new uint16[](10);
        routes_[0] = 1; // routeAaveV2
        routes_[1] = 2; // routeMaker
        routes_[2] = 3; // routeMakerCompound
        routes_[3] = 4; // routeMakerAave
        routes_[4] = 5; // routeBalancer
        routes_[5] = 6; // routeBalancerCompound
        routes_[6] = 7; // routeBalancerAave
        routes_[7] = 9; // routeAaveV3
        routes_[8] = 10; // routeSpark
        routes_[9] = 11; // routeMorpho
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury. Will be called manually.
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

contract InstaFlashAggregator is FlashAggregator {
    using SafeERC20 for IERC20;

    /* 
     Deprecated
    */
    // function initialize(address[] memory _ctokens, address owner_) public {
    //     require(status == 0, "cannot-call-again");
    //     require(stETHStatus == 0, "only-once");
    //     require(ownerStatus == 0, "only-once");
    //     IERC20(daiTokenAddr).safeApprove(address(makerLending), type(uint256).max);
    //     addTokenToCToken(_ctokens);
    //     address[] memory cTokens_ = new address[](2);
    //     cTokens_[0] = cethTokenAddr;
    //     cTokens_[1] = cdaiTokenAddr;
    //     uint256[] memory errors_ = troller.enterMarkets(cTokens_);
    //     for(uint256 j = 0; j < errors_.length; j++){
    //         require(errors_[j] == 0, "Comptroller.enterMarkets failed.");
    //     }
    //     IERC20(stEthTokenAddr).safeApprove(address(wstEthToken), type(uint256).max);
    //     owner = owner_;
    //     ownerStatus = 1;
    //     stETHStatus = 1;
    //     status = 1;
    // }

    /* 
     Deprecated
    */
    // function initialize() public {
    //     require(initializeStatus == 0, "cannot-call-again");
    //     IERC20(daiTokenAddr).safeApprove(address(makerLending), type(uint256).max);
    //     initializeStatus = 1;
    // }

    receive() external payable {}
}
