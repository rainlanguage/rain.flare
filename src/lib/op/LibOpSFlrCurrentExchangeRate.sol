// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Operand} from "rain.interpreter.interface/interface/deprecated/IInterpreterV2.sol";
import {
    LibFixedPointDecimalArithmeticOpenZeppelin,
    Math
} from "rain.math.fixedpoint/lib/LibFixedPointDecimalArithmeticOpenZeppelin.sol";
import {IStakedFlr} from "../../interface/IStakedFlr.sol";

/// @dev Immutable upgradeable proxy contract to the sFLR contract.
IStakedFlr constant SFLR_CONTRACT = IStakedFlr(address(0x12e605bc104e93B45e1aD99F9e555f659051c2BB));

/// @title LibOpSLFRCurrentExchangeRate
/// Implements the `sflrCurrentExchangeRate` externed opcode.
library LibOpSLFRCurrentExchangeRate {
    /// Extern integrity for getting the current exchange rate of FLR to SFLR.
    function integrity(Operand, uint256, uint256) internal pure returns (uint256, uint256) {
        return (0, 1);
    }

    /// Extern implementation for reading the current exchange rate of FLR to sFLR
    /// based on directly reading the underlying assets self-reported by the sFLR contract.
    function run(Operand, uint256[] memory) internal view returns (uint256[] memory) {
        uint256 rate18 = SFLR_CONTRACT.getSharesByPooledFlr(1e18);
        uint256[] memory outputs;
        assembly ("memory-safe") {
            outputs := mload(0x40)
            mstore(0x40, add(outputs, 0x40))

            mstore(outputs, 1)
            mstore(add(outputs, 0x20), rate18)
        }
        return outputs;
    }
}
