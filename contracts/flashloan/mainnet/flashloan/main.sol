
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
    AaveReceiverInterface,
    MakerReceiverInterface
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

        ExecuteOperationVariables memory e;
        e._length = assets.length;
        e._tokenContracts = new IERC20[](e._length);

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );

        for (uint i = 0; i < e._length; i++) {
            e._tokenContracts[i] = IERC20(assets[i]);
            e._tokenContracts[i].safeApprove(aaveLendingAddr, amounts[i] + premiums[i]);
            e._tokenContracts[i].safeTransfer(sender_, amounts[i]);
        }

        AaveReceiverInterface(sender_).executeOperation(assets, amounts, premiums, sender_, _data);

        return true;
    }
    
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {

        // require(initiator == address(this), "not-same-sender");
        require(msg.sender == makerLendingAddr, "not-maker-sender");

        (address sender_, bytes memory data_) = abi.decode(
            data,
            (address, bytes)
        );

        IERC20 _tokenContract = IERC20(token);
        _tokenContract.safeApprove(makerLendingAddr, amount + fee);
        _tokenContract.safeTransfer(sender_, amount);

        MakerReceiverInterface(sender_).onFlashLoan(sender_, token, amount, fee, data);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function routeAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory data) internal {
        uint _length = _tokens.length;
        uint[] memory _modes = new uint[](_length);
        for (uint i = 0; i < _length; i++) {
            _modes[i]=0;
        }

        uint[] memory iniBals = new uint[](_length);
        uint[] memory finBals = new uint[](_length);
        IERC20[] memory _tokenContracts = new IERC20[](_length);

        for (uint i = 0; i < _length; i++) {
            _tokenContracts[i] = IERC20(_tokens[i]);
            iniBals[i] = _tokenContracts[i].balanceOf(address(this));
        }

        aaveLending.flashLoan(address(this), _tokens, _amounts, _modes, address(0), data, 3228);

        for (uint i = _length; i < _length; i++) {
            address _token = _tokens[i];
            finBals[i] = _tokenContracts[i].balanceOf(address(this));
            require(iniBals[i] <= finBals[i], "amount-paid-less");
        }

        emit LogFlashLoan(
            msg.sender,
            _tokens,
            _amounts
        );
    }

    function routeMaker(address _token, uint256 _amount, bytes memory data) internal {
        IERC20 _tokenContract = IERC20(_token);
        uint iniBals = _tokenContract.balanceOf(address(this));
        uint finBals;

        makerLending.flashLoan(MakerReceiverInterface(address(this)), _token, _amount, data);

        finBals = _tokenContract.balanceOf(address(this));
        require(iniBals <= finBals, "amount-paid-less");

        address[] memory tokens_ = new address[](1);
        uint[] memory amounts_ = new uint[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;

        emit LogFlashLoan(
            msg.sender,
            tokens_,
            amounts_
        );
    }

    function flashLoan(	
        address[] memory tokens_,	
        uint256[] memory amounts_,
        uint256 route_,
        bytes calldata data_
    ) external {	
        if (route_ == 1) {
            bytes memory data = abi.encode(msg.sender, data_);
            routeAave(tokens_, amounts_, data);	
        } else if (route_ == 2) {
            bytes memory data = abi.encode(msg.sender, data_);
            routeMaker(tokens_[0], amounts_[0], data);	
        } else {
            require(false, "route-do-not-exist");
        }
    }
}

contract InstaFlashloanAggregator is FlashResolver {

    receive() external payable {}

}