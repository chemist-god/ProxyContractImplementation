// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title EIP-1967 Transparent Proxy Contract
 * @dev Provides upgradeability while preventing storage collisions. 
 * Follows exact EIP-1967 specifications for storage slots.
 * 
 * References:
 * - EIP-1967: https://eips.ethereum.org/EIPS/eip-1967
 * - OpenZeppelin Implementation: https://github.com/OpenZeppelin/openzeppelin-contracts
 */
contract Proxy {
    // EIP-1967 defined storage slots
    bytes32 private constant _IMPLEMENTATION_SLOT = 
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _ADMIN_SLOT = 
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the implementation is upgraded
     */
    event Upgraded(address indexed newImplementation);

    /**
     * @dev Initializes the proxy with initial implementation and admin
     * @param implementation_ Address of the initial implementation contract
     * @param admin_ Address of the proxy admin
     */
    constructor(address implementation_, address admin_) {
        _setImplementation(implementation_);
        _setAdmin(admin_);
    }

    /**
     * @dev Upgrades the implementation address
     * @param newImplementation Address of the new implementation contract
     */
    function upgradeTo(address newImplementation) external {
        require(msg.sender == admin(), "Proxy: caller is not admin");
        _setImplementation(newImplementation);
    }

    /**
     * @dev Internal function to set the implementation address
     */
    function _setImplementation(address newImplementation) private {
        require(newImplementation != address(0), "Proxy: invalid implementation");
        require(
            newImplementation.code.length > 0,
            "Proxy: implementation is not contract"
        );
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Internal function to set the admin address
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "Proxy: invalid admin");
        assembly {
            sstore(_ADMIN_SLOT, newAdmin)
        }
    }

    /**
     * @dev Fallback function delegates all calls to implementation contract
     */
    fallback() external payable {
        assembly {
            // Load implementation from EIP-1967 slot
            let impl := sload(_IMPLEMENTATION_SLOT)
            
            // Validate implementation is contract
            if iszero(extcodesize(impl)) {
                revert(0, 0)
            }
            
            // Copy calldata to memory
            calldatacopy(0, 0, calldatasize())
            
            // Delegatecall to implementation
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            
            // Copy return data
            returndatacopy(0, 0, returndatasize())
            
            // Handle results
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Returns current implementation address
     */
    function implementation() public view returns (address) {
        address impl;
        assembly {
            impl := sload(_IMPLEMENTATION_SLOT)
        }
        return impl;
    }

    /**
     * @dev Returns current admin address
     */
    function admin() public view returns (address) {
        address adm;
        assembly {
            adm := sload(_ADMIN_SLOT)
        }
        return adm;
    }

    /**
     * @dev Receive function for empty calldata (ETH transfers)
     */
    receive() external payable {}
}