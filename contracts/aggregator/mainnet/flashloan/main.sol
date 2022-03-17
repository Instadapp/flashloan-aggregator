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
    CTokenInterface,
    InstaFlashReceiverInterface
} from "./interfaces.sol";

contract Setups is Helper {
    using SafeERC20 for IERC20;

    /**
     * @dev Add to token to cToken mapping.
     * @notice Add to token to cToken mapping.
     * @param _cTokens list of cToken addresses to be added to the mapping.
    */
    function addTokenToCToken(address[] memory _cTokens) public {
        for (uint i = 0; i < _cTokens.length; i++) {
            (bool isMarket_,,) = troller.markets(_cTokens[i]);
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
        require(msg.sender == makerLendingAddr, "not-maker-sender");

        FlashloanVariables memory instaLoanVariables_;

        (uint route_, address[] memory tokens_, uint256[] memory amounts_, address sender_, bytes memory data_) = abi.decode(
            _data,
            (uint, address[], uint256[], address, bytes)
        );

        instaLoanVariables_._tokens = tokens_;
        instaLoanVariables_._amounts = amounts_;
        instaLoanVariables_._iniBals = calculateBalances(tokens_, address(this));
        instaLoanVariables_._instaFees = calculateFees(amounts_, calculateFeeBPS(route_));

        if (route_ == 2) {
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(sender_)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }
            
        } else if (route_ == 3 || route_ == 4) {
            require(_fee == 0, "flash-DAI-fee-not-0");

            address[] memory _daiTokenList = new address[](1);
            uint256[] memory _daiTokenAmountsList = new uint256[](1);
            _daiTokenList[0] = daiToken;
            _daiTokenAmountsList[0] = _amount;

            if (route_ == 3) {
                compoundSupply(_daiTokenList, _daiTokenAmountsList);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupply(_daiTokenList, _daiTokenAmountsList);
                aaveBorrow(tokens_, amounts_);
            }
            
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(sender_)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            if (route_ == 3) {
                compoundPayback(tokens_, amounts_);
                compoundWithdraw(_daiTokenList, _daiTokenAmountsList);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdraw(_daiTokenList, _daiTokenAmountsList);
            }
        } else {
            revert("wrong-route");
        }

        instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
        validateFlashloan(instaLoanVariables_);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
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
        require(msg.sender == balancerLendingAddr, "not-balancer-sender");

        FlashloanVariables memory instaLoanVariables_;

        (uint route_, address[] memory tokens_, uint256[] memory amounts_, address sender_, bytes memory data_) = abi.decode(
            _data,
            (uint, address[], uint256[], address, bytes)
        );

        instaLoanVariables_._tokens = tokens_;
        instaLoanVariables_._amounts = amounts_;
        instaLoanVariables_._iniBals = calculateBalances(tokens_, address(this));
        instaLoanVariables_._instaFees = calculateFees(amounts_, calculateFeeBPS(route_));

        if (route_ == 5) {
            if (tokens_[0] == stEth) {
                wstEth.unwrap(_amounts[0]);
            }
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(sender_)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            if (tokens_[0] == stEth) {
                wstEth.wrap(amounts_[0]);
            }

            instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
            if (tokens_[0] == stEth) {
                // adding 10 wei to avoid any possible decimal errors in final calculations
                instaLoanVariables_._finBals[0] = instaLoanVariables_._finBals[0] + 10;
                instaLoanVariables_._tokens[0] = address(wstEth);
            }
            validateFlashloan(instaLoanVariables_);
            safeTransferWithFee(instaLoanVariables_, _fees, balancerLendingAddr);
        } else if (route_ == 6 || route_ == 7) {
            require(_fees[0] == 0, "flash-ETH-fee-not-0");

            address[] memory wEthTokenList = new address[](1);
            wEthTokenList[0] = wEthToken;

            if (route_ == 6) {
                compoundSupply(wEthTokenList, _amounts);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupply(wEthTokenList, _amounts);
                aaveBorrow(tokens_, amounts_);
            }

            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(sender_)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            if (route_ == 6) {
                compoundPayback(tokens_, amounts_);
                compoundWithdraw(wEthTokenList, _amounts);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdraw(wEthTokenList, _amounts);
            }
            instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
            validateFlashloan(instaLoanVariables_);
            instaLoanVariables_._tokens = wEthTokenList;
            instaLoanVariables_._amounts = _amounts;
            safeTransferWithFee(instaLoanVariables_, _fees, balancerLendingAddr);
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
     * @dev Middle function for route 2.
     * @notice Middle function for route 2.
     * @param _token token address for flashloan(DAI).
     * @param _amount DAI amount for flashloan.
     * @param _data extra data passed.
    */
    function routeMaker(address _token, uint256 _amount, bytes memory _data) internal {
        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;
        bytes memory data_ = abi.encode(2, tokens_, amounts_, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), _token, _amount, data_);
    }

    /**
     * @dev Middle function for route 3.
     * @notice Middle function for route 3.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeMakerCompound(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(3, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data_);
    }
    
    /**
     * @dev Middle function for route 4.
     * @notice Middle function for route 4.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeMakerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(4, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data_);
    }

    /**
     * @dev Middle function for route 5.
     * @notice Middle function for route 5.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeBalancer(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for(uint256 i = 0 ; i < length_ ; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        bytes memory data_ = abi.encode(5, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        if (_tokens[0] == stEth) {
            require(length_ == 1, "steth-length-should-be-1");
            tokens_[0] = IERC20(address(wstEth));
            _amounts[0] = wstEth.getWstETHByStETH(_amounts[0]);
        }
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), tokens_, _amounts, data_);
    }

    /**
     * @dev Middle function for route 6.
     * @notice Middle function for route 6.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeBalancerCompound(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(6, _tokens, _amounts, msg.sender, _data);
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wEthToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), wethTokenList_, wethAmountList_, data_);
    }
    
    /**
     * @dev Middle function for route 7.
     * @notice Middle function for route 7.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeBalancerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(7, _tokens, _amounts, msg.sender, _data);
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wEthToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), wethTokenList_, wethAmountList_, data_);
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
        } else {
            revert("route-does-not-exist");
        }
        
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
        routes_ = new uint16[](7);
        routes_[0] = 1;
        routes_[1] = 2;
        routes_[2] = 3;
        routes_[3] = 4;
        routes_[4] = 5;
        routes_[5] = 6;
        routes_[6] = 7;
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury. Will be called manually.
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

contract InstaFlashAggregator is FlashAggregator {
    using SafeERC20 for IERC20;
    /* 
     Deprecated
    */
    // function initialize(address[] memory _ctokens) public {
    //     require(status == 0, "cannot-call-again");
    //     IERC20(daiToken).safeApprove(makerLendingAddr, type(uint256).max);
    //     addTokenToCToken(_ctokens);
    //     address[] memory cTokens_ = new address[](2);
    //     cTokens_[0] = cEthToken;
    //     cTokens_[1] = cDaiToken;
    //     uint256[] memory errors_ = troller.enterMarkets(cTokens_);
    //     for(uint256 j = 0; j < errors_.length; j++){
    //         require(errors_[j] == 0, "Comptroller.enterMarkets failed.");
    //     }
    //     status = 1;
    // }

    // new initialize for stEth allowance
    function initialize() external {
        require(stETHStatus == 0, "only-once");
        IERC20(stEth).approve(address(wstEth), type(uint256).max);
        stETHStatus = 1;
    }

    receive() external payable {}

}