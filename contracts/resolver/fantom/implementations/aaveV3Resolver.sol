//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveV3DataProvider {
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            bool,
            bool,
            bool
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address,
            address,
            address
        );
}

contract Variable {
    IAaveV3DataProvider public constant aaveV3DataProvider =
        IAaveV3DataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);
}

contract AaveV3Resolver is Variable {
    function getAvailability(
        uint256 _route,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) public view returns (bool) {
        require(_route == 9, "invalid-route");
        uint256 length = _tokens.length;
        for (uint256 i = 0; i < length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            (, , , , , , , , bool isActive, ) = aaveV3DataProvider
                .getReserveConfigurationData(_tokens[i]);
            (address aTokenAddr, , ) = aaveV3DataProvider
                .getReserveTokensAddresses(_tokens[i]);
            if (isActive == false) return false;
            if (token_.balanceOf(aTokenAddr) < _amounts[i]) return false;
        }
        return true;
    }
}
