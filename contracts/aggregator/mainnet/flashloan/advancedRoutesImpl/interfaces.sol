//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface InstaFlashReceiverInterface {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata _data
    ) external returns (bool);
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface CTokenInterface {
    function mint(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function underlying() external view returns (address);
}

interface CEthInterface {
    function mint() external payable;

    function redeemUnderlying(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;
}

interface IWeth is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface IAaveLending {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);

    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    function flashLoan(
        InstaFlashReceiverInterface receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    function toll() external view returns (uint256);
}

interface ProtocolFeesCollector {
    function getFlashLoanFeePercentage() external view returns (uint256);
}

interface IBalancerLending {
    function flashLoan(
        InstaFlashReceiverInterface recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    function getProtocolFeesCollector()
        external
        view
        returns (ProtocolFeesCollector);
}
