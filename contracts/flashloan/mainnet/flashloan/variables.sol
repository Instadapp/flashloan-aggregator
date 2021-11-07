//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    IndexInterface,
    ListInterface,
    TokenInterface,
    IAaveLending,
    IERC3156FlashLender, 
    Comptroller
} from "./interfaces.sol";

contract Variables {

    // IndexInterface public constant instaIndex = IndexInterface(address(0)); // TODO: update at the time of deployment
    // ListInterface public immutable instaList = ListInterface(address(0)); // TODO: update at the time of deployment

    // address public immutable wchainToken = address(0); // TODO: update at the time of deployment
    // address public constant chainToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // TokenInterface public wchainContract = TokenInterface(wchainToken);

    address public constant aaveLendingAddr = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    IAaveLending public constant aaveLending = IAaveLending(aaveLendingAddr);

    address public constant makerLendingAddr = 0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853;
    IERC3156FlashLender public constant makerLending = IERC3156FlashLender(makerLendingAddr);

    address public constant daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDaiToken = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    uint256 public constant daiBorrowAmount = 500000000000000000000000000;

    address public constant comptrollerAddr = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    Comptroller public constant troller = Comptroller(comptrollerAddr);

    mapping(address => address) public tokenToCToken;

    constructor() {
        tokenToCToken[daiToken] = cDaiToken; // DAI
        tokenToCToken[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // USDT
        tokenToCToken[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC
        // TODO: need to add all tokens
    }
}