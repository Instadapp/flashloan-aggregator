//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract ConstantVariables {
    address public constant aaveV2LendingAddr =
        0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    IAaveLending public constant aaveV2Lending =
        IAaveLending(aaveV2LendingAddr);

    address public constant aaveV3LendingAddr =
        0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    IAaveV3Lending public constant aaveV3Lending =
        IAaveV3Lending(aaveV3LendingAddr);

    address public constant balancerLendingAddr =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    IBalancerLending public constant balancerLending =
        IBalancerLending(balancerLendingAddr);

    address public constant wEthToken =
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    uint256 public constant wethBorrowAmountPercentage = 80;

    address public constant treasuryAddr =
        0x6e9d36eaeC63Bc3aD4A47fb0d7826A9922AAfC22;
    address private constant instaListAddr =
        0x839c2D3aDe63DF5b0b8F3E57D5e145057Ab41556;
    ListInterface public constant instaList = ListInterface(instaListAddr);

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%
    address public constant uniswapFactoryAddr =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
}

contract Variables is ConstantVariables {
    bytes32 internal dataHash;
    // if 1 then can enter flashlaon, if 2 then callback
    uint256 internal status;

    struct FlashloanVariables {
        address[] _tokens;
        uint256[] _amounts;
        uint256[] _iniBals;
        uint256[] _finBals;
        uint256[] _instaFees;
    }

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}
