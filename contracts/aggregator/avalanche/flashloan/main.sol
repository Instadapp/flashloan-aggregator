//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Flashloan.
 * @dev Flashloan aggregator.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { Helper } from "./helpers.sol";

import { 
    TokenInterface,
    InstaFlashReceiverInterface
} from "./interfaces.sol";

contract FlashAggregatorAvalanche is Helper {
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
        instaLoanVariables_._instaFees = calculateFees(_amounts, calculateFeeBPS(1));
        instaLoanVariables_._iniBals = calculateBalances(_assets, address(this));

        safeApprove(instaLoanVariables_, _premiums, aaveLendingAddr);
        safeTransfer(instaLoanVariables_, sender_);

        if (checkIfDsa(sender_)) {
            Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
        } else {
            InstaFlashReceiverInterface(sender_).executeOperation(_assets, _amounts, instaLoanVariables_._instaFees, sender_, data_);
        }

        instaLoanVariables_._finBals = calculateBalances(_assets, address(this));
        validateFlashloan(instaLoanVariables_);

        return true;
    }

    /**
     * @dev Fallback function for balancer flashloan.
     * @notice Fallback function for balancer flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _fees list of fees for the corresponding addresses for flashloan.
     * @param _data extra data passed(includes route info aswell).
    */
    function onInstaLoan(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        address,
        bytes memory _data
    ) external verifyDataHash(_data) {
        require(msg.sender == interopLendingAddr, "not-interop-sender");

        FlashloanVariables memory instaLoanVariables_;

        (uint route_, address[] memory tokens_, uint256[] memory amounts_, address sender_, bytes memory data_) = abi.decode(
            _data,
            (uint, address[], uint256[], address, bytes)
        );

        instaLoanVariables_._tokens = tokens_;
        instaLoanVariables_._amounts = amounts_;
        instaLoanVariables_._iniBals = calculateBalances(tokens_, address(this));
        instaLoanVariables_._instaFees = calculateFees(amounts_, calculateFeeBPS(route_));

        if (route_ == 8) {
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(sender_)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
            validateFlashloan(instaLoanVariables_);
            safeTransferWithFee(instaLoanVariables_, _fees, interopLendingAddr);
        } else if (route_ == 9) {
            aaveSupply(_tokens, _amounts);
            aaveBorrow(tokens_, amounts_);
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(sender_)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            aavePayback(tokens_, amounts_);
            aaveWithdraw(_tokens, _amounts);
            
            instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
            validateFlashloan(instaLoanVariables_);
            instaLoanVariables_._amounts = _amounts;
            instaLoanVariables_._tokens = _tokens;
            safeTransferWithFee(instaLoanVariables_, _fees, interopLendingAddr);
        } else {
            revert("wrong-route");
        }
    }

    /**
     * @dev Middle function for route 1.
     * @notice Middle function for route 1.
     * @param _tokens list of token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _data extra data passed.
    */
    function routeAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(msg.sender, _data);
        uint length_ = _tokens.length;
        uint[] memory _modes = new uint[](length_);
        for (uint i = 0; i < length_; i++) {
            _modes[i]=0;
        }
        dataHash = bytes32(keccak256(data_));
        aaveLending.flashLoan(address(this), _tokens, _amounts, _modes, address(0), data_, 3228);
    }

    /**
     * @dev Middle function for route 9.
     * @notice Middle function for route 9.
     * @param _tokens list of token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeInterop(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(8, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        interopLending.initiateInstaLoan(address(this), _tokens, _amounts, data_);
    }

    /**
     * @dev Middle function for route 9.
     * @notice Middle function for route 9.
     * @param _tokens list of token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
     * @param _instaData extra data passed.
    */
    function routeInteropAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data, bytes memory _instaData) internal {
        (address[] memory tokens_, uint256[] memory amounts_) = abi.decode(
            _instaData,
            (address[], uint256[])
        );
        bytes memory data_ = abi.encode(9, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        interopLending.initiateInstaLoan(address(this), tokens_, amounts_, data_);
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
        bytes calldata _instaData
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
            routeInterop(_tokens, _amounts, _data);
        } else if (_route == 9) {
            routeInteropAave(_tokens, _amounts, _data, _instaData);
        } else {
            revert("route-does-not-exist");
        }

        uint256 length_ = _tokens.length;
        uint256[] memory amounts_ = new uint256[](length_);

        for(uint256 i = 0; i < length_; i++) {
            amounts_[i] = type(uint).max;
        }

        transferFeeToTreasury(_tokens);

        emit LogFlashloan(
            msg.sender,
            _route,
            _tokens,
            _amounts
        );
    }

    /**
     * @dev Function to get the list of available routes.
     * @notice Function to get the list of available routes.
    */
    function getRoutes() public pure returns (uint16[] memory routes_) {
        routes_ = new uint16[](3);
        routes_[0] = 1;
        routes_[1] = 8;
        routes_[2] = 9;
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury.
     * @param _tokens token addresses for transferring fee to treasury.
    */
    function transferFeeToTreasury(address[] memory _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            uint decimals_ = TokenInterface(_tokens[i]).decimals();
            uint amtToSub_ = decimals_ == 18 ? 1e10 : decimals_ > 12 ? 10000 : decimals_ > 7 ? 100 : 10;
            uint amtToTransfer_ = token_.balanceOf(address(this)) > amtToSub_ ? (token_.balanceOf(address(this)) - amtToSub_) : 0;
            if (amtToTransfer_ > 0) token_.safeTransfer(treasuryAddr, amtToTransfer_);
        }
    }
}

contract InstaFlashAggregatorAvalanche is FlashAggregatorAvalanche {
    function initialize() public  {
        require(status == 0, "cannot-call-again");
        status = 1;
    }

    receive() external payable {}
}
