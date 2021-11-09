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

    // function calFee(uint[] memory amts_) external view returns (uint[] memory finalAmts_, uint[] memory premiums_, uint fee_) {
    //     fee_ = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
    //     for (uint i = 0; i < amts_.length; i++) {
    //         premiums_[i] = (amts_[i] * fee_) / 10000;
    //         finalAmts_[i] = finalAmts_[i] + premiums_[i];
    //     }
    // }

    struct ExecuteOperationVariables {
        uint256 _length;
        IERC20[] _tokenContracts;
    }
    
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata _data
    ) external returns (bool) {
        require(initiator == address(this), "not-same-sender");
        require(msg.sender == aaveLendingAddr, "not-aave-sender");
        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );
        uint256[] memory InstaFees = calculateFees(amounts, calculateFeeBPS(1));
        SafeApprove(assets, amounts, premiums, aaveLendingAddr);
        SafeTransfer(assets, amounts, sender_);
        InstaFlashReceiverInterface(sender_).executeOperation(assets, amounts, InstaFees, sender_, data_);
        return true;
    }
    
    // function onFlashLoan(
    //     address initiator,
    //     address,
    //     uint256 amount,
    //     uint256 fee,
    //     bytes calldata data
    // ) external returns (bytes32) {
    //     require(initiator == address(this), "not-same-sender");
    //     require(msg.sender == makerLendingAddr, "not-maker-sender");

    //     (uint route, address[] memory tokens, uint256[] memory amounts, address sender_, bytes memory data_) = abi.decode(
    //         data,
    //         (uint, address[], uint256[], address, bytes)
    //     );
    //     uint256 length = tokens.length;
    //     uint256[] memory fees = new uint256[](length);
    //     for (uint i = 0; i < length; i++) {
    //         fees[i] = amounts[i] * InstaFee / (10 ** 4);
    //     }
    //     if (route == 2) {
    //         SafeTransfer(tokens, amounts, sender_);
    //         InstaFlashReceiverInterface(sender_).executeOperation(tokens, amounts, fees, sender_, data_);
    //     } else if (route == 3 || route == 4) {
    //         require(fee == 0, "flash-DAI-fee-not-0");
    //         if (route == 3) {
    //             CompoundSupplyDAI(amount);
    //             CompoundBorrow(tokens, amounts);
    //         } else {
    //             AaveSupplyDAI(amount);
    //             AaveBorrow(tokens, amounts);
    //         }
    //         SafeTransfer(tokens, amounts, sender_);
    //         InstaFlashReceiverInterface(sender_).executeOperation(tokens, amounts, fees, sender_, data_);
    //         if (route == 3) {
    //             CompoundPayback(tokens, amounts);
    //             CompoundWithdrawDAI(amount);
    //         } else {
    //             AavePayback(tokens, amounts);
    //             AaveWithdrawDAI(amount);
    //         }
    //     } else {
    //         require(false, "wrong-route");
    //     }
    //     return keccak256("ERC3156FlashBorrower.onFlashLoan");
    // }

    function routeAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory data_) internal {
        bytes memory data = abi.encode(msg.sender, data_);
        uint _length = _tokens.length;
        uint[] memory _modes = new uint[](_length);
        for (uint i = 0; i < _length; i++) {
            _modes[i]=0;
        }
        aaveLending.flashLoan(address(this), _tokens, _amounts, _modes, address(0), data, 3228);
    }

    // function routeMaker(address _token, uint256 _amount, bytes memory data_) internal {
    //     address[] memory tokens = new address[](1);
    //     uint256[] memory amounts = new uint256[](1);
    //     tokens[0] = _token;
    //     amounts[0] = _amount;
    //     bytes memory data = abi.encode(2, tokens, amounts, msg.sender, data_);
    //     makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), _token, _amount, data);
    // }

    // function routeMakerCompound(address[] memory _tokens, uint256[] memory _amounts, bytes memory data_) internal {
    //     bytes memory data = abi.encode(3, _tokens, _amounts, msg.sender, data_);
    //     makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data);
    // }
    
    // function routeMakerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory data_) internal {
    //     bytes memory data = abi.encode(4, _tokens, _amounts, msg.sender, data_);
    //     makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data);
    // }

    function flashLoan(	
        address[] memory tokens_,	
        uint256[] memory amounts_,
        uint256 route_,
        bytes calldata data_
    ) external {
        require(route_ == 1, "route-does-not-exist");
        uint[] memory iniBals = CalculateBalances(address(this), tokens_);

        if (route_ == 1) {
            routeAave(tokens_, amounts_, data_);	
        }
        // } else if (route_ == 2) {
        //     routeMaker(tokens_[0], amounts_[0], data_);	
        // } else if (route_ == 3) {
        //     routeMakerCompound(tokens_, amounts_, data_);
        // } else if (route_ == 4) {
        //     routeMakerAave(tokens_, amounts_, data_);
        // }

        uint[] memory finBals = CalculateBalances(address(this), tokens_);
        require(Validate(iniBals, finBals) == true, "amount-paid-less");
        emit LogFlashLoan(
            msg.sender,
            tokens_,
            amounts_
        );
    }
}

contract InstaFlashloanAggregator is FlashResolver {

    // constructor() {
    //     TokenInterface(daiToken).approve(makerLendingAddr, type(uint256).max);
    // }

    receive() external payable {}

}
