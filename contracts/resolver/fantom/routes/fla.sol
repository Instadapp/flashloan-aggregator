//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FLAResolver {
    address public flashloanAggregatorAddr =
        0x22ed23Cc6EFf065AfDb7D5fF0CBf6886fd19aee1;

    function initialize(address fla) public {
        flashloanAggregatorAddr = fla;
    }

    function getAvailability(
        uint256 _route,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) public view returns (bool) {
        require(_route == 10, "invalid-route");
        uint256 length = _tokens.length;
        for (uint256 i = 0; i < length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            if (token_.balanceOf(flashloanAggregatorAddr) < _amounts[i])
                return false;
        }
        return true;
    }
}
