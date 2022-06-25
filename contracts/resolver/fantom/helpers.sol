//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import { Variables } from "./variables.sol";
import '@openzeppelin/contracts/utils/Address.sol';
import { InstaFlashloanAggregatorInterface } from "./interfaces.sol";

contract Helper is Variables {

    function getRoutesWithAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (uint16[] memory) {        
        (uint16[] memory _routesAll) = flashloanAggregator.getEnabledRoutes();
        uint256 length = _routesAll.length;
        uint256 j = 0;
        uint16[] memory _routesWithAvailability = new uint16[](length);
        for(uint256 i = 0; i < length; i++) {
            if(getAvailability(_routesAll[i], _tokens, _amounts)) {
                _routesWithAvailability[j] = _routesAll[i];
                j++;
            } else {
            require(false, "invalid-route-2");
            }
        }
        return _routesWithAvailability;
    }

    function getAvailability( uint256 _route, address[] memory _tokens, uint256[] memory _amounts) public view returns (bool) {
        bytes memory _output = Address.functionStaticCall(routeToResolver[_route], abi.encodeWithSelector(this.getAvailability.selector, _route,_tokens,_amounts), 'getAvailability-call-failed');
        return abi.decode(_output, (bool));
    }

    function bubbleSort(address[] memory _tokens, uint256[] memory _amounts)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            for (uint256 j = 0; j < _tokens.length - i - 1; j++) {
                if (_tokens[j] > _tokens[j + 1]) {
                    (
                        _tokens[j],
                        _tokens[j + 1],
                        _amounts[j],
                        _amounts[j + 1]
                    ) = (
                        _tokens[j + 1],
                        _tokens[j],
                        _amounts[j + 1],
                        _amounts[j]
                    );
                }
            }
        }
        return (_tokens, _amounts);
    }

    function validateTokens(address[] memory _tokens) internal pure {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            require(_tokens[i] != _tokens[i + 1], "non-unique-tokens");
        }
    }
}
