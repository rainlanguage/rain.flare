// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {OperandV2, StackItem} from "rain.interpreter.interface/interface/unstable/IInterpreterV4.sol";
import {LibSceptreStakedFlare} from "../sflr/LibSceptreStakedFlare.sol";
import {LibDecimalFloat, Float} from "rain.math.float/lib/LibDecimalFloat.sol";

/// @title LibOpSLFRCurrentExchangeRate
/// Implements the `sflrCurrentExchangeRate` externed opcode.
library LibOpSLFRCurrentExchangeRate {
    /// Extern integrity for getting the current exchange rate of FLR to SFLR.
    function integrity(OperandV2, uint256, uint256) internal pure returns (uint256, uint256) {
        return (0, 1);
    }

    /// Extern implementation for reading the current exchange rate of FLR to sFLR
    /// based on directly reading the underlying assets self-reported by the sFLR contract.
    function run(OperandV2, StackItem[] memory) internal view returns (StackItem[] memory) {
        uint256 rate18 = LibSceptreStakedFlare.getSFLRPerFLR18();
        Float rateFloat = LibDecimalFloat.fromFixedDecimalLosslessPacked(rate18, 18);
        StackItem[] memory outputs;
        assembly ("memory-safe") {
            outputs := mload(0x40)
            mstore(0x40, add(outputs, 0x40))

            mstore(outputs, 1)
            mstore(add(outputs, 0x20), rateFloat)
        }
        return outputs;
    }
}
