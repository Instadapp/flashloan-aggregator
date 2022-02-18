//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Flashloan.
 * @dev Flashloan aggregator.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {Helper} from "./helpers.sol";

import {TokenInterface, InstaFlashReceiverInterface, Comptroller, IERC3156FlashLender} from "./interfaces.sol";

contract Setups is Helper {
    using SafeERC20 for IERC20;

    /**
     * @dev Add to token to crToken mapping.
     * @notice Add to token to crToken mapping.
     * @param _crTokens list of crToken addresses to be added to the mapping.
     */
    function addTokenToCrToken(address[] memory _crTokens) public {
        address wavax = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        tokenToCrToken[wavax] = _crTokens[0];

        address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        tokenToCrToken[weth] = _crTokens[1];

        address usdt = address(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
        tokenToCrToken[usdt] = _crTokens[2];

        address usdc = address(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
        tokenToCrToken[usdc] = _crTokens[3];

        address dai = address(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70);
        tokenToCrToken[dai] = _crTokens[4];

        address wbtc = address(0x50b7545627a5162F82A992c33b87aDc75187B218);
        tokenToCrToken[wbtc] = _crTokens[5];

        address link = address(0x5947BB275c521040051D82396192181b413227A3);
        tokenToCrToken[link] = _crTokens[6];
    }
}

contract FlashAggregatorAvalanche is Setups {
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
        require(msg.sender == aaveLendingAddr, "not-aave-sender");

        FlashloanVariables memory instaLoanVariables_;

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );

        instaLoanVariables_._tokens = _assets;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(1)
        );
        instaLoanVariables_._iniBals = calculateBalances(
            _assets,
            address(this)
        );

        safeApprove(instaLoanVariables_, _premiums, aaveLendingAddr);
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

    struct info {
        address _initiator;
        address _token;
        uint256 _amount;
        uint256 _fee;
    }

    /**
     * @dev Fallback function for makerdao or cream-finance flashloan.
     * @notice Fallback function for makerdao and cream-finance flashloan.
     */
    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external verifyDataHash(_data) returns (bytes32) {
        info memory data;
        data._initiator = _initiator;
        data._token = _token;
        data._amount = _amount;
        data._fee = _fee;

        //require(a._initiator == address(this), "not-same-sender");
        // require(
        //      msg.sender == lendingAddr,
        //     "not-cream-sender"
        // );

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

        require(
            Comptroller(comptroller).isMarketListed(msg.sender),
            "untrusted message sender"
        );
        // require(
        //     a._initiator == address(this),
        //     "FlashBorrower: Untrusted loan initiator"
        // );
        // (address borrowToken, uint256 borrowAmount) = abi.decode(
        //     _data,
        //     (address, uint256)
        // );
        // require(
        //     borrowToken == a._token,
        //     "encoded data (borrowToken) does not match"
        // );
        // require(
        //     borrowAmount == a._amount,
        //     "encoded data (borrowAmount) does not match"
        // );
        IERC20(data._token).approve(msg.sender, data._amount + data._fee);

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

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /**
     * @dev Middle function for route 1.
     * @notice Middle function for route 1.
     * @param _tokens list of token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _data extra data passed.
     */
    function routeAave(
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
        aaveLending.flashLoan(
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
     * @dev Middle function for route 8.
     * @notice Middle function for route 8.
     * @param _token token address for flashloan.
     * @param _amount token amount for flashloan.
     * @param _data extra data passed.
     */
    function routeCreamFinance(
        address _token,
        uint256 _amount,
        bytes memory _data
    ) internal {
        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;
        bytes memory data_ = abi.encode(
            8,
            tokens_,
            amounts_,
            msg.sender,
            _data
        );
        address crToken = tokenToCrToken[_token];
        IERC3156FlashLender creamLending = IERC3156FlashLender(crToken);
        dataHash = bytes32(keccak256(data_));
        creamLending.flashLoan(
            InstaFlashReceiverInterface(address(this)),
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
            routeAave(_tokens, _amounts, _data);
        } else if (_route == 2) {
            revert("this route is only for mainnet");
        } else if (_route == 3) {
            revert("this route is only for mainnet");
        } else if (_route == 4) {
            revert("this route is only for mainnet");
        } else if (_route == 5) {
            revert("this route is only for mainnet, polygon and arbitrum");
        } else if (_route == 6) {
            revert("this route is only for mainnet");
        } else if (_route == 7) {
            revert("this route is only for mainnet and polygon");
        } else if (_route == 8) {
            routeCreamFinance(_tokens[0], _amounts[0], _data);
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
        routes_[0] = 1;
        routes_[1] = 8;
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

contract InstaFlashAggregatorAvalanche is FlashAggregatorAvalanche {
    /* 
     Deprecated
    */
    function initialize(address[] memory _crtokens) public {
        require(status == 0, "cannot-call-again");
        addTokenToCrToken(_crtokens);

        status = 1;
    }

    receive() external payable {}
}
