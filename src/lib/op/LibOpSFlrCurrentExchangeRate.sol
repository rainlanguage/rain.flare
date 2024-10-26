// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.19;

import {Operand} from "rain.interpreter.interface/interface/deprecated/IInterpreterV2.sol";
import {
    LibFixedPointDecimalArithmeticOpenZeppelin,
    Math
} from "rain.math.fixedpoint/lib/LibFixedPointDecimalArithmeticOpenZeppelin.sol";
import {LibSceptreStakedFlare} from "../sflr/LibSceptreStakedFlare.sol";

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
        uint256 rate18 = LibSceptreStakedFlare.getSFLRPerFLR18();
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
