// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Upgraded Implementation Contract
 * @notice Demonstrates storage-compatible upgrades
 * @dev Maintains same storage layout as V1 with added functionality
 */
contract ImplementationV2 {
    // Storage slots must match previous implementation
    uint256 public value;
    address public lastUpdater;
    
    // New state variables must be added after existing ones
    uint256 public updateCount;

    /**
     * @dev Enhanced setValue with count tracking
     */
    function setValue(uint256 newValue) external {
        require(newValue != value, "Value must change");
        value = newValue;
        lastUpdater = msg.sender;
        updateCount++;
    }

    /**
     * @dev New functionality
     */
    function getValueSquared() external view returns (uint256) {
        return value * value;
    }
}