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
    ) external returns (bool) {
        bytes memory response_ = spell(AAVE_IMPL, msg.data);
        return (abi.decode(response_, (bool)));
    }

    /**
     * @dev Fallback function for makerdao and euler flashloan.
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
    ) external returns (bytes32) {
        (uint256 route_, , , , ) = abi.decode(
            _data,
            (uint256, address[], uint256[], address, bytes)
        );
        bytes memory response_;

        if (route_ == 2 || route_ == 3 || route_ == 4) {
            response_ = spell(MAKER_IMPL, msg.data);
        } else if (route_ == 10) {
            response_ = spell(EULER_IMPL, msg.data);
        }
        return (abi.decode(response_, (bytes32)));
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
    ) external {
        spell(BALANCER_IMPL, msg.data);
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

    function onDeferredLiquidityCheck(bytes memory _data) external {
        spell(EULER_IMPL, msg.data);
    }

    function routeFLA(
        address _receiverAddress,
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal reentrancy returns (bool) {
        //TODO: doubt

        FlashloanVariables memory instaLoanVariables_;
        instaLoanVariables_._tokens = _tokens;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(9, _receiverAddress)
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
    ) external {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        if (_route == 1) {
            spell(AAVE_IMPL, msg.data);
        } else if (_route == 2) {
            spell(MAKER_IMPL, msg.data);
        } else if (_route == 3) {
            spell(MAKER_IMPL, msg.data);
        } else if (_route == 4) {
            spell(MAKER_IMPL, msg.data);
        } else if (_route == 5) {
            spell(BALANCER_IMPL, msg.data);
        } else if (_route == 6) {
            spell(BALANCER_IMPL, msg.data);
        } else if (_route == 7) {
            spell(BALANCER_IMPL, msg.data);
        } else if (_route == 8) {
            spell(UNISWAP_IMPL, msg.data);
        } else if (_route == 9) {
            (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
            validateTokens(_tokens);
            routeFLA(msg.sender, _tokens, _amounts, _data);
        } else if (_route == 10) {
            spell(EULER_IMPL, msg.data);
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
        routes_ = new uint16[](9);
        routes_[0] = 1;
        routes_[1] = 2;
        routes_[2] = 3;
        routes_[3] = 4;
        routes_[4] = 5;
        routes_[5] = 6;
        routes_[6] = 7;
        routes_[7] = 8;
        routes_[8] = 9;
        routes_[9] = 10;
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
    function initialize(
        address[] memory _ctokens,
        address owner_,
        address aave,
        address balancer,
        address euler,
        address maker,
        address uniswap
    ) public {
        require(status == 0, "cannot-call-again");
        require(stETHStatus == 0, "only-once");
        require(ownerStatus == 0, "only-once");
        IERC20(daiTokenAddr).safeApprove(
            address(makerLending),
            type(uint256).max
        );
        addTokenToCToken(_ctokens);
        address[] memory cTokens_ = new address[](2);
        cTokens_[0] = cethTokenAddr;
        cTokens_[1] = cdaiTokenAddr;
        uint256[] memory errors_ = troller.enterMarkets(cTokens_);
        for (uint256 j = 0; j < errors_.length; j++) {
            require(errors_[j] == 0, "Comptroller.enterMarkets failed.");
        }
        IERC20(stEthTokenAddr).approve(address(wstEthToken), type(uint256).max);
        owner = owner_;
        ownerStatus = 1;
        stETHStatus = 1;
        status = 1;
        AAVE_IMPL = aave;
        BALANCER_IMPL = balancer;
        EULER_IMPL = euler;
        MAKER_IMPL = maker;
        UNISWAP_IMPL = uniswap;
    }

    receive() external payable {}
}
