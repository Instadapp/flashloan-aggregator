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

contract FlashAggregatorAvalanche is Helper {
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

    function flashLoan(	
        address[] memory _tokens,	
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data,
        bytes calldata
    ) external reentrancy {

        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        if (_route == 1) {
            routeAave(_tokens, _amounts, _data);
        } else if (_route == 2) {
            require(false, "this route is only for mainnet");
        } else if (_route == 3) {
            require(false, "this route is only for mainnet");
        } else if (_route == 4) {
            require(false, "this route is only for mainnet");
        } else if (_route == 5) {
            require(false, "this route is only for mainnet, polygon and arbitrum");
        } else if (_route == 6) {
            require(false, "this route is only for mainnet");
        } else if (_route == 7) {
            require(false, "this route is only for mainnet and polygon");
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
        routes_ = new uint16[](1);
        routes_[0] = 1;
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

contract InstaFlashloanAggregatorAvalanche is FlashAggregatorAvalanche {

    // constructor() {
    //     TokenInterface(daiToken).approve(makerLendingAddr, type(uint256).max);
    // }

    receive() external payable {}

}
