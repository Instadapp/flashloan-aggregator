//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../../../common/helpers.sol";
import "./variable.sol";

contract Helper is Variables, TokenHelpers, FlashloanHelpers {
    using SafeERC20 for IERC20;

    /**
     * @dev Returns to true if the passed address is a DSA else returns false.
     * @notice Returns to true if the passed address is a DSA else returns false.
     * @param _account account to check for, if DSA.
     */
    function checkIfDsa(address _account) internal view returns (bool) {
        return instaList.accountID(_account) > 0;
    }

     /**
     * @dev Returns fee for the passed route in BPS.
     * @notice Returns fee for the passed route in BPS. 1 BPS == 0.01%.
     * @param _route route number for flashloan.
     */
    function calculateFeeBPS(uint256 _route)
        public
        view
        virtual
        returns (uint256 BPS_)
    {
        bytes memory _output = Address.functionStaticCall(
            routeToImplementation[_route],
            msg.data,
            "calculateFeeBPS-call-failed"
        );
        BPS_ = abi.decode(_output, (uint256));
    }

    /**
     * @dev Function to get the list of all routes.
     * @notice Function to get the list of all routes.
     */
    function getRoutes() public view returns (uint256[] memory) {
        return routes;
    }

    /**
     * @dev Function to get the list of enabled routes.
     * @notice Function to get the list of enabled routes.
     */
    function getEnabledRoutes()
        public
        view
        returns (uint16[] memory routesEnabled_)
    {
        uint256[] memory routesAll_ = getRoutes();
        uint256 length = routesAll_.length;
        uint256 _count = 0;

        for (uint256 i = 0; i < length; i++) {
            if (routeStatus[routesAll_[i]] == true) {
                _count++;
            }
        }

        routesEnabled_ = new uint16[](_count);
        uint256 k = 0;

        for (uint256 j = 0; j < length; j++) {
            if (routeStatus[routesAll_[j]]) {
                routesEnabled_[k] = uint16(routesAll_[j]);
                k++;
            }
        }
    }
}
