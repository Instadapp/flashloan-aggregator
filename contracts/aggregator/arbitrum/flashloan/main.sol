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

contract FlashAggregatorArbitrum is Helper {
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
    ) external verifyDataHash(_data) {
        require(msg.sender == balancerLendingAddr, "not-aave-sender");

        FlashloanVariables memory instaLoanVariables_;

        uint256 length_ = _tokens.length;
        instaLoanVariables_._tokens = new address[](length_);
        for(uint256 i = 0; i < length_ ; i++) {
            instaLoanVariables_._tokens[i] = address(_tokens[i]);
        }

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );

        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._iniBals = calculateBalances(instaLoanVariables_._tokens, address(this));
        instaLoanVariables_._instaFees = calculateFees(_amounts, calculateFeeBPS(5));

        safeTransfer(instaLoanVariables_, sender_);

        if (checkIfDsa(msg.sender)) {
            InstaFlashReceiverInterface(sender_).cast(instaLoanVariables_._tokens, _amounts, instaLoanVariables_._instaFees, sender_, data_);
        } else {
            InstaFlashReceiverInterface(sender_).executeOperation(instaLoanVariables_._tokens, _amounts, instaLoanVariables_._instaFees, sender_, data_);
        }
        
        instaLoanVariables_._finBals = calculateBalances(instaLoanVariables_._tokens, address(this));
        validateFlashloan(instaLoanVariables_);

        safeTransferWithFee(instaLoanVariables_, _fees, balancerLendingAddr);
    }

    function routeBalancer(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(msg.sender, _data);
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for(uint256 i = 0 ; i < length_ ; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), tokens_, _amounts, data_);
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

    function getRoutes() public pure returns (uint16[] memory routes_) {
        routes_ = new uint16[](1);
        routes_[0] = 5;
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

contract InstaFlashloanAggregatorArbitrum is FlashAggregatorArbitrum {

    // constructor() {
    //     TokenInterface(daiToken).approve(makerLendingAddr, type(uint256).max);
    // }

    receive() external payable {}

}
