// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Initial Implementation Contract
 * @dev Example logic contract with upgradeable storage
 */
contract ImplementationV1 {
    uint256 public value;
    address public lastUpdater;

    /**
     * @dev Sets a new value (example function)
     * @param newValue The value to set
     */
    function setValue(uint256 newValue) external {
        value = newValue;
        lastUpdater = msg.sender;
    }

    /**
     * @dev Gets the current value plus offset
     * @param offset Number to add
     */
    function getValuePlus(uint256 offset) external view returns (uint256) {
        return value + offset;
    }
}