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
    InstaFlashReceiverInterface
} from "./interfaces.sol";

contract FlashAggregator is Helper {
    using SafeERC20 for IERC20;

    event LogFlashLoan(
        address indexed dsa,
        address[] tokens,
        uint256[] amounts
    );    

    function receiveFlashLoan(
        IERC20[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        bytes memory _data
    ) external {
        require(msg.sender == balancerLendingAddr, "not-aave-sender");

        uint256 length_ = _tokens.length;
        address[] memory tokens_ = new address[](length_);
        for(uint256 i = 0; i < length_ ; i++) {
            tokens_[i] = address(_tokens[i]);
        }

        uint[] memory iniBals_ = calculateBalances(tokens_, address(this));

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );
        uint256[] memory InstaFees_ = calculateFees(_amounts, calculateFeeBPS(5));

        safeTransfer(tokens_, _amounts, sender_);
        InstaFlashReceiverInterface(sender_).executeOperation(tokens_, _amounts, InstaFees_, sender_, data_);
        
        uint[] memory finBals = calculateBalances(tokens_, address(this));
        require(validate(iniBals_, finBals, InstaFees_) == true, "amount-paid-less");

        safeTransferWithFee(tokens_, _amounts, _fees, balancerLendingAddr);
    }

    function routeBalancer(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(msg.sender, _data);
        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for(uint256 i = 0 ; i < length_ ; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), tokens_, _amounts, data_);
    }

    function flashLoan(	
        address[] memory _tokens,	
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data
    ) external {

        if (_route == 1) {
            require(false, "this route is only for mainnet, polygon and avalanche");	
        } else if (_route == 2) {
            require(false, "this route is only for mainnet");
        } else if (_route == 3) {
            require(false, "this route is only for mainnet");
        } else if (_route == 4) {
            require(false, "this route is only for mainnet");
        } else if (_route == 5) {
            routeBalancer(_tokens, _amounts, _data);
        } else if (_route == 6) {
            require(false, "this route is only for mainnet");
        } else if (_route == 7) {
            require(false, "this route is only for mainnet and polygon");
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

contract InstaFlashloanAggregatorArbitrum is FlashAggregator {

    // constructor() {
    //     TokenInterface(daiToken).approve(makerLendingAddr, type(uint256).max);
    // }

    receive() external payable {}

}
