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

    function routeAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(msg.sender, _data);
        uint length_ = _tokens.length;
        uint[] memory _modes = new uint[](length_);
        for (uint i = 0; i < length_; i++) {
            _modes[i]=0;
        }
        aaveLending.flashLoan(address(this), _tokens, _amounts, _modes, address(0), data_, 3228);
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
            require(false, "this route is only for mainnet");
        } else if (_route == 3) {
            require(false, "this route is only for mainnet");
        } else if (_route == 4) {
            require(false, "this route is only for mainnet");
        } else if (_route == 5) {
            require(false, "this is route only for mainnet, polygon and arbitrum");
        } else if (_route == 6) {
            require(false, "this is route only for mainnet");
        } else if (_route == 7) {
            require(false, "this is route only for mainnet and polygon");
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

contract InstaFlashloanAggregatorAvalanche is FlashResolver {

    // constructor() {
    //     TokenInterface(daiToken).approve(makerLendingAddr, type(uint256).max);
    // }

    receive() external payable {}

}
