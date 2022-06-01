//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HelpersCommon {
    using SafeERC20 for IERC20;

    /**
     * @dev Delegate the calls to Connector.
     * @param _target Connector address
     * @param _data CallData of function.
    */
    function spell(address _target, bytes memory _data) internal returns (bytes memory response) {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()
            
            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    returndatacopy(0x00, 0x00, size)
                    revert(0x00, size)
                }
        }
    }

    /**
     * @dev Calculates the balances..
     * @notice Calculates the balances of the account passed for the tokens.
     * @param _tokens list of token addresses to calculate balance for.
     * @param _account account to calculate balance for.
     */
    function calculateBalances(address[] memory _tokens, address _account)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 _length = _tokens.length;
        uint256[] memory balances_ = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            balances_[i] = token.balanceOf(_account);
        }
        return balances_;
    }

    /**
     * @dev Validates if token addresses are unique. Just need to check adjacent tokens as the array was sorted first
     * @notice Validates if token addresses are unique.
     * @param _tokens list of token addresses.
     */
    function validateTokens(address[] memory _tokens) internal pure {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            require(_tokens[i] != _tokens[i + 1], "non-unique-tokens");
        }
    }

    /**
     * @dev Calculate fees for the respective amounts and fee in BPS passed.
     * @notice Calculate fees for the respective amounts and fee in BPS passed. 1 BPS == 0.01%.
     * @param _amounts list of amounts.
     * @param _BPS fee in BPS.
     */
    function calculateFees(uint256[] memory _amounts, uint256 _BPS)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 length_ = _amounts.length;
        uint256[] memory InstaFees = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            InstaFees[i] = (_amounts[i] * _BPS) / (10**4);
        }
        return InstaFees;
    }

    /**
     * @dev Sort the tokens and amounts arrays according to token addresses.
     * @notice Sort the tokens and amounts arrays according to token addresses.
     * @param _tokens list of token addresses.
     * @param _amounts list of respective amounts.
     */
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

    /**
     * @dev Sort the tokens and amounts arrays according to token addresses.
     * @notice Sort the tokens and amounts arrays according to token addresses.
     * @param _token0 address of token0.
     * @param _token1 address of token1.
     */
    function sortTokens(address _token0, address _token1)
        internal
        pure
        returns (address, address)
    {
        if(_token1 < _token0) {
            (_token0, _token1) = (_token1, _token0);
        }
        return (_token0 , _token1);
    }
}
