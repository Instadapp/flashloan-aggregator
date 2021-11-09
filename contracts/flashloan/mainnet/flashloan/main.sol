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
            require(tokenToCToken[token_] == address((0)), "already-unabled");
            tokenToCToken[token_] = ctokens_[i];
            IERC20(token_).safeApprove(ctokens_[i], type(uint256).max);
        }
    }
}

contract FlashResolver is Setups {
    using SafeERC20 for IERC20;

    event LogFlashLoan(
        address indexed dsa,
        address[] tokens,
        uint256[] amounts
    );

    // struct ExecuteOperationVariables {
    //     uint256 _length;
    //     IERC20[] _tokenContracts;
    // }
    
    function executeOperation(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address _initiator,
        bytes calldata _data
    ) external returns (bool) {
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == aaveLendingAddr, "not-aave-sender");

        uint[] memory iniBals_ = calculateBalances(_assets, address(this));

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );
        uint256[] memory InstaFees_ = calculateFees(_amounts, calculateFeeBPS(1));
        safeApprove(_assets, _amounts, _premiums, aaveLendingAddr);
        safeTransfer(_assets, _amounts, sender_);
        InstaFlashReceiverInterface(sender_).executeOperation(_assets, _amounts, InstaFees_, sender_, data_);

        uint[] memory finBals = calculateBalances(_assets, address(this));
        require(validate(iniBals_, finBals, InstaFees_) == true, "amount-paid-less");

        return true;
    }
    
    function onFlashLoan(
        address _initiator,
        address,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external returns (bytes32) {
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == makerLendingAddr, "not-maker-sender");

        address[] memory token_ = new address[](1);
        token_[0] = daiToken;
        uint[] memory iniBals_ = calculateBalances(token_, address(this));

        (uint route_, address[] memory tokens_, uint256[] memory amounts_, address sender_, bytes memory data_) = abi.decode(
            _data,
            (uint, address[], uint256[], address, bytes)
        );

        uint256[] memory InstaFees_ = calculateFees(amounts_, calculateFeeBPS(route_));

        if (route_ == 2) {
            safeTransfer(tokens_, amounts_, sender_);
            InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, InstaFees_, sender_, data_);
        } else if (route_ == 3 || route_ == 4) {
            require(_fee == 0, "flash-DAI-fee-not-0");
            if (route_ == 3) {
                compoundSupplyDAI(_amount);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupplyDAI(_amount);
                aaveBorrow(tokens_, amounts_);
            }
            safeTransfer(tokens_, amounts_, sender_);
            InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, InstaFees_, sender_, data_);
            if (route_ == 3) {
                compoundPayback(tokens_, amounts_);
                compoundWithdrawDAI(_amount);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdrawDAI(_amount);
            }
        } else {
            require(false, "wrong-route");
        }

        uint[] memory finBals_ = calculateBalances(token_, address(this));
        require(validate(iniBals_, finBals_, InstaFees_) == true, "amount-paid-less");

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function routeAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(msg.sender, _data);
        uint length_ = _tokens.length;
        uint[] memory _modes = new uint[](length_);
        for (uint i = 0; i < length_; i++) {
            _modes[i]=0;
        }
        aaveLending.flashLoan(address(this), _tokens, _amounts, _modes, address(0), data_, 3228);
    }

    function routeMaker(address _token, uint256 _amount, bytes memory _data) internal {
        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;
        bytes memory data = abi.encode(2, tokens_, amounts_, msg.sender, _data);
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), _token, _amount, data);
    }

    function routeMakerCompound(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(3, _tokens, _amounts, msg.sender, _data);
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data_);
    }
    
    function routeMakerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(4, _tokens, _amounts, msg.sender, _data);
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data_);
    }

    function flashLoan(	
        address[] memory _tokens,	
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data
    ) external {
        require(_route == 1 || _route == 2 || _route == 3 || _route == 4, "route-does-not-exist");

        if (_route == 1) {
            routeAave(_tokens, _amounts, _data);	
        } else if (_route == 2) {
            routeMaker(_tokens[0], _amounts[0], _data);	
        } else if (_route == 3) {
            routeMakerCompound(_tokens, _amounts, _data);
        } else if (_route == 4) {
            routeMakerAave(_tokens, _amounts, _data);
        }

        emit LogFlashLoan(
            msg.sender,
            _tokens,
            _amounts
        );
    }
}

contract InstaFlashloanAggregator is FlashResolver {
    using SafeERC20 for IERC20;

    constructor() {
        IERC20(daiToken).safeApprove(makerLendingAddr, type(uint256).max);
    }

    receive() external payable {}

}
