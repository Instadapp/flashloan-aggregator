//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FLAResolver {

    address public flashloanAggregatorAddr =
        0x2b65731A085B55DBe6c7DcC8D717Ac36c00F6d19;//todo: update

    function initialize(address fla) public {
        flashloanAggregatorAddr = fla;
    }

    function getAvailability( uint256 _route, address[] memory _tokens, uint256[] memory _amounts) public view returns (bool) {
        require(_route == 10, 'invalid-route');
        uint length = _tokens.length;
        for (uint256 i = 0; i < length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            if (token_.balanceOf(flashloanAggregatorAddr) < _amounts[i]) return false;
        }
        return true;
    }
}
