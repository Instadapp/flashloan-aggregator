//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CommonVariablesV1 {
   
    bytes32 internal dataHash;
    // if 1 then can enter flashlaon, if 2 then callback
    uint256 internal status;

    /**
     * @dev  better checking by double encoding the data.
     * @notice better checking by double encoding the data.
     * @param data_ data passed.
     */
    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        require(dataHash_ == dataHash && dataHash_ != bytes32(0), 'invalid-data-hash');
        require(status == 2, 'already-entered');
        dataHash = bytes32(0);
        _;
        status = 1;
    }

    /**
     * @dev reentrancy gaurd.
     * @notice reentrancy gaurd.
     */
    modifier reentrancy() {
        require(status == 1, 'already-entered');
        status = 2;
        _;
        require(status == 1, 'already-entered');
    }
}
