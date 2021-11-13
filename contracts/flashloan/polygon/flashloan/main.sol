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
    IAaveLending, 
    InstaFlashReceiverInterface
} from "./interfaces.sol";

contract FlashResolver is Helper {
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

    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        bytes memory _data
    ) external {
        require(msg.sender == balancerLendingAddr, "not-aave-sender");

        (uint route_, address[] memory tokens_, uint256[] memory amounts_, address sender_, bytes memory data_) = abi.decode(
            _data,
            (uint, address[], uint256[], address, bytes)
        );
        uint[] memory iniBals_ = calculateBalances(tokens_, address(this));
        uint256[] memory InstaFees_ = calculateFees(amounts_, calculateFeeBPS(route_));

        if (route_ == 2) {
            safeTransfer(tokens_, amounts_, sender_);
            InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, InstaFees_, sender_, data_);
            uint[] memory finBals = calculateBalances(tokens_, address(this));
            require(validate(iniBals_, finBals, InstaFees_) == true, "amount-paid-less");
            safeTransferWithFee(tokens_, _amounts, _fees, balancerLendingAddr);
        } else if (route_ == 3) {
            require(_fees[0] == 0, "flash-ETH-fee-not-0");
            aaveSupply(wEthToken, _amounts[0]);
            aaveBorrow(tokens_, amounts_);
            safeTransfer(tokens_, amounts_, sender_);
            InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, InstaFees_, sender_, data_);
            aavePayback(tokens_, amounts_);
            aaveWithdraw(wEthToken, _amounts[0]);
            uint[] memory finBals = calculateBalances(tokens_, address(this));
            require(validate(iniBals_, finBals, InstaFees_) == true, "amount-paid-less");
            address[] memory wethTokenAddrList_ = new address[](1);
            wethTokenAddrList_[0] = wEthToken;
            safeTransferWithFee(wethTokenAddrList_, _amounts, _fees, balancerLendingAddr);
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
        aaveLending.flashLoan(address(this), _tokens, _amounts, _modes, address(0), data_, 3228);
    }

    function routeBalancer(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for(uint256 i = 0 ; i < length_ ; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        bytes memory data_ = abi.encode(2, _tokens, _amounts, msg.sender, _data);
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), tokens_, _amounts, data_);
    }
    
    function routeBalancerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(3, _tokens, _amounts, msg.sender, _data);
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wEthToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), wethTokenList_, wethAmountList_, data_);
    }

    function flashLoan(	
        address[] memory _tokens,	
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data
    ) external {

        if (_route == 1) {
            routeAave(_tokens, _amounts, _data);	
        } else if (_route == 2) {
            routeBalancer(_tokens, _amounts, _data);
        } else if (_route == 3) {
            routeBalancerAave(_tokens, _amounts, _data);
        } else {
            require(false, "route-does-not-exist");
        } 

        emit LogFlashLoan(
            msg.sender,
            _tokens,
            _amounts
        );
    }
}

contract InstaFlashloanAggregatorPolygon is FlashResolver {

    // constructor() {
    //     TokenInterface(daiToken).approve(makerLendingAddr, type(uint256).max);
    // }

    receive() external payable {}

}
