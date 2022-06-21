//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Flashloan.
 * @dev Flashloan aggregator for Fantom.
 */
import "./helpers.sol";
import "hardhat/console.sol";

contract FlashAggregatorFantom is Helper {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
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

    function routeFLA(
        address _receiverAddress,
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal reentrancy returns (bool) {//TODO: doubt

        console.log("Inside routefla");

        FlashloanVariables memory instaLoanVariables_;
        instaLoanVariables_._tokens = _tokens;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(
            _amounts,
            calculateFeeBPS(10)
        );
        console.log("AAVE_IMPL: ", AAVE_IMPL);
        instaLoanVariables_._iniBals = calculateBalances(
            _tokens,
            address(this)
        );
        console.log("_iniBals: ", instaLoanVariables_._iniBals[0]);
        safeTransfer(instaLoanVariables_, _receiverAddress);

        if (checkIfDsa(_receiverAddress)) {
            Address.functionCall(
                _receiverAddress,
                _data,
                "DSA-flashloan-fallback-failed"
            );
        } else {
            require(InstaFlashReceiverInterface(_receiverAddress).executeOperation(
                _tokens,
                _amounts,
                instaLoanVariables_._instaFees,
                _receiverAddress,
                _data
            ), "invalid flashloan execution");
        }

        instaLoanVariables_._finBals = calculateBalances(
            _tokens,
            address(this)
        );
        console.log("_finBals: ", instaLoanVariables_._finBals[0]);
        validateFlashloan(instaLoanVariables_);

        status = 1;
        return true;
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
            (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
            validateTokens(_tokens);
            routeFLA(msg.sender, _tokens, _amounts, _data);
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
    function getRoutes() public view returns (uint16[] memory routes_) {
        console.log("Inside getRoutes main");
        routes_ = new uint16[](2);
        routes_[0] = 9;
        routes_[1] = 10;
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury.
     * @param _tokens token addresses for transferring fee to treasury.
    */
    function transferFeeToTreasury(address[] memory _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            uint decimals_ = TokenInterface(_tokens[i]).decimals();
            uint amtToSub_ = decimals_ == 18 ? 1e10 : decimals_ > 12 ? 10000 : decimals_ > 7 ? 100 : 10;
            uint amtToTransfer_ = token_.balanceOf(address(this)) > amtToSub_ ? (token_.balanceOf(address(this)) - amtToSub_) : 0;
            if (amtToTransfer_ > 0) token_.safeTransfer(treasuryAddr, amtToTransfer_);
        }
    }
}

contract InstaFlashAggregatorFantom is FlashAggregatorFantom {

    function initialize(address aave) public {
        require(status == 0, "cannot-call-again");
        status = 1;
        AAVE_IMPL = aave;
        console.log("AAVE_IMPL: ", AAVE_IMPL);
    }

    receive() external payable {}
}