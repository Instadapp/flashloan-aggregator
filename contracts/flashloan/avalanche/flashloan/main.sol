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

        uint[] memory iniBals = calculateBalances(address(this), assets);

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );
        uint256[] memory InstaFees = calculateFees(amounts, calculateFeeBPS(1));
        safeApprove(assets, amounts, premiums, aaveLendingAddr);
        safeTransfer(assets, amounts, sender_);
        InstaFlashReceiverInterface(sender_).executeOperation(assets, amounts, InstaFees, sender_, data_);

        uint[] memory finBals = calculateBalances(address(this), assets);
        require(validate(iniBals, finBals, InstaFees) == true, "amount-paid-less");

        return true;
    }

    function routeAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory data_) internal {
        bytes memory data = abi.encode(msg.sender, data_);
        uint _length = _tokens.length;
        uint[] memory _modes = new uint[](_length);
        for (uint i = 0; i < _length; i++) {
            _modes[i]=0;
        }
        aaveLending.flashLoan(address(this), _tokens, _amounts, _modes, address(0), data, 3228);
    }

    function flashLoan(	
        address[] memory tokens_,	
        uint256[] memory amounts_,
        uint256 route_,
        bytes calldata data_
    ) external {
        require(route_ == 1, "route-does-not-exist");

        if (route_ == 1) {
            routeAave(tokens_, amounts_, data_);	
        }

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
