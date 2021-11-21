//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";
import { Helper } from "./helpers.sol";

import { 
    IndexInterface,
    ListInterface,
    TokenInterface,
    CTokenInterface,
    IAaveLending, 
    InstaFlashReceiverInterface
} from "./interfaces.sol";


contract Setups is Helper {
    using SafeERC20 for IERC20;

    function addTokenToCtoken(address[] memory ctokens_) external {
        for (uint i = 0; i < ctokens_.length; i++) {
            (bool isMarket_,,) = troller.markets(ctokens_[i]);
            require(isMarket_, "unvalid-ctoken");
            address token_ = CTokenInterface(ctokens_[i]).underlying();
            require(tokenToCToken[token_] == address((0)), "already-added");
            tokenToCToken[token_] = ctokens_[i];
            IERC20(token_).safeApprove(ctokens_[i], type(uint256).max);
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

        if (checkIfDsa(msg.sender)) {
            InstaFlashReceiverInterface(sender_).cast(_assets, _amounts, instaLoanVariables_._instaFees, sender_, data_);
        } else {
            InstaFlashReceiverInterface(sender_).executeOperation(_assets, _amounts, instaLoanVariables_._instaFees, sender_, data_);
        }

        instaLoanVariables_._finBals = calculateBalances(_assets, address(this));
        validateFlashloan(instaLoanVariables_);

        return true;
    }
    
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

            if (checkIfDsa(msg.sender)) {
                InstaFlashReceiverInterface(sender_).cast(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }
            
        } else if (route_ == 3 || route_ == 4) {
            require(_fee == 0, "flash-DAI-fee-not-0");
            if (route_ == 3) {
                compoundSupply(daiToken, _amount);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupply(daiToken, _amount);
                aaveBorrow(tokens_, amounts_);
            }
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(msg.sender)) {
                InstaFlashReceiverInterface(sender_).cast(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            if (route_ == 3) {
                compoundPayback(tokens_, amounts_);
                compoundWithdraw(daiToken, _amount);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdraw(daiToken, _amount);
            }
        } else {
            require(false, "wrong-route");
        }

        instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
        validateFlashloan(instaLoanVariables_);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        bytes memory _data
    ) external verifyDataHash(_data) {
        require(msg.sender == balancerLendingAddr, "not-aave-sender");

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
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(msg.sender)) {
                InstaFlashReceiverInterface(sender_).cast(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
            validateFlashloan(instaLoanVariables_);
            safeTransferWithFee(instaLoanVariables_, _fees, balancerLendingAddr);
        } else if (route_ == 6 || route_ == 7) {
            require(_fees[0] == 0, "flash-ETH-fee-not-0");
            if (route_ == 6) {
                compoundSupply(chainToken, _amounts[0]);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupply(wEthToken, _amounts[0]);
                aaveBorrow(tokens_, amounts_);
            }
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(msg.sender)) {
                InstaFlashReceiverInterface(sender_).cast(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            if (route_ == 6) {
                compoundPayback(tokens_, amounts_);
                compoundWithdraw(chainToken, _amounts[0]);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdraw(wEthToken, _amounts[0]);
            }
            instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
            validateFlashloan(instaLoanVariables_);
            instaLoanVariables_._amounts = _amounts;
            instaLoanVariables_._tokens = new address[](1);
            instaLoanVariables_._tokens[0] = wEthToken;
            safeTransferWithFee(instaLoanVariables_, _fees, balancerLendingAddr);
        } else {
            require(false, "wrong-route");
        }
    }

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

    function routeMaker(address _token, uint256 _amount, bytes memory _data) internal {
        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;
        bytes memory data_ = abi.encode(2, tokens_, amounts_, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), _token, _amount, data_);
    }

    function routeMakerCompound(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(3, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data_);
    }
    
    function routeMakerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(4, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data_);
    }

    function routeBalancer(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for(uint256 i = 0 ; i < length_ ; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        bytes memory data_ = abi.encode(5, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), tokens_, _amounts, data_);
    }

    function routeBalancerCompound(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(6, _tokens, _amounts, msg.sender, _data);
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wEthToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), wethTokenList_, wethAmountList_, data_);
    }
    
    function routeBalancerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(7, _tokens, _amounts, msg.sender, _data);
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wEthToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), wethTokenList_, wethAmountList_, data_);
    }

    function flashLoan(	
        address[] memory _tokens,	
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data,
        bytes calldata // adding this if we might need some extra data to decide route in future cases. Not using it anywhere at the moment.
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
            require(false, "route-does-not-exist");
        }

        uint256 length_ = _tokens.length;
        uint256[] memory amounts_ = new uint256[](length_);

        for(uint256 i = 0; i < length_; i++) {
            amounts_[i] = type(uint).max;
        }

        transferFeeToTreasury(_tokens, amounts_);
        
        emit LogFlashloan(
            msg.sender,
            _route,
            _tokens,
            _amounts
        );
    }

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

    function transferFeeToTreasury(address[] memory _tokens, uint256[] memory _amounts) public {
        require(_tokens.length == _amounts.length, "length-not-same");
        for(uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            if (_amounts[i] == type(uint).max) {
                token_.transfer(treasuryAddr, token_.balanceOf(address(this)));
            } else {
                token_.transfer(treasuryAddr, _amounts[i]);
            }
        }
    }
}

contract InstaFlashloanAggregator is FlashAggregator {
    using SafeERC20 for IERC20;

    constructor() {
        IERC20(daiToken).safeApprove(makerLendingAddr, type(uint256).max);
    }

    receive() external payable {}

}
