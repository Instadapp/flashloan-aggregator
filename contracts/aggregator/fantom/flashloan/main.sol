//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Flashloan.
 * @dev Flashloan aggregator for Fantom.
 */
import "./helpers.sol";

contract AdminModule is Helper {
    event updateOwnerLog(address indexed oldOwner, address indexed newOwner);

    event updateWhitelistLog(
        address indexed account,
        bool indexed isWhitelisted_
    );

    /**
     * @dev owner gaurd.
     * @notice owner gaurd.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "not-owner");
        _;
    }

    /**
     * @dev Update owner.
     * @notice Update owner.
     * @param newOwner_ address of new owner.
     */
    function updateOwner(address newOwner_) external onlyOwner {
        address oldOwner_ = owner;
        owner = newOwner_;
        emit updateOwnerLog(oldOwner_, newOwner_);
    }
}

contract FlashAggregatorFantom is AdminModule {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );

    event LogCollectRevenue(
        address to,
        address[] tokens,
        uint256[] amounts
    );
    
    /**
     * @dev Callback function for aave flashloan.
     * @notice Callback function for aave flashloan.
     * @param _assets list of asset addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets for flashloan.
     * @param _premiums list of premiums/fees for the corresponding addresses for flashloan.
     * @param _initiator initiator address for flashloan.
     * @param _data extra data passed.
    */
    function executeOperation(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _premiums,
        address _initiator,
        bytes memory _data
    ) external returns (bool) {
        bytes memory response_ = spell(AAVE_IMPL, msg.data);
        return (abi.decode(response_, (bool)));
    }

    /**
     * @dev Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @notice Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _route route for flashloan.
     * @param _data extra data passed.
    */
    function flashLoan(
        address[] memory _tokens,	
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data,
        bytes calldata // kept for future use by instadapp. Currently not used anywhere.
    ) external {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);


       if (_route == 9) {
            spell(AAVE_IMPL, msg.data);
        } else if (_route == 10){
            spell(FLA_IMPL, msg.data);
        } else {
            revert("route-does-not-exist");
        }

        emit LogFlashloan(
            msg.sender,
            _route,
            _tokens,
            _amounts
        );
    }

    /**
     * @dev Function to get the list of available routes.
     * @notice Function to get the list of available routes.
    */
    function getRoutes() public pure returns (uint16[] memory routes_) {
        routes_ = new uint16[](2);
        routes_[0] = 9;
        routes_[1] = 10;
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury. Will be called manually.
     * @param _tokens token addresses for transferring fee to treasury.
     * @param _to treasury address.
     */
    function transferFee(address[] memory _tokens, address _to) public onlyOwner {
        uint256[] memory _amts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            uint256 decimals_ = TokenInterface(_tokens[i]).decimals();
            uint256 amtToSub_ = decimals_ == 18 ? 1e10 : decimals_ > 12
                ? 10000
                : decimals_ > 7
                ? 100
                : 10;
            _amts[i] = token_.balanceOf(address(this)) > amtToSub_
                ? (token_.balanceOf(address(this)) - amtToSub_)
                : 0;
            if (_amts[i] > 0)
                token_.safeTransfer(_to, _amts[i]);
        }
        emit LogCollectRevenue(_to, _tokens, _amts);
    }
}

contract InstaFlashAggregatorFantom is FlashAggregatorFantom {

    function initialize(address owner_, address aave_, address fla_) public {
        require(status == 0, "cannot-call-again");
        require(ownerStatus == 0, "only-once");
        owner = owner_;
        ownerStatus = 1;
        status = 1;
        AAVE_IMPL = aave_;
        FLA_IMPL = fla_;
    }

    receive() external payable {}
}