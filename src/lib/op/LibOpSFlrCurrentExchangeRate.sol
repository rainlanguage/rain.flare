// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {OperandV2, StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {LibSceptreStakedFlare} from "../sflr/LibSceptreStakedFlare.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

/// @title LibOpSFLRCurrentExchangeRate
/// Implements the `sflrCurrentExchangeRate` externed opcode.
library LibOpSFLRCurrentExchangeRate {
    /// Extern integrity for getting the current sFLR-per-FLR exchange rate.
    /// Takes 0 inputs, produces 1 output.
    function integrity(OperandV2, uint256, uint256) internal pure returns (uint256, uint256) {
        return (0, 1);
    }

    /// Extern implementation for reading the current sFLR-per-FLR exchange rate
    /// based on directly reading the underlying assets self-reported by the
    /// Sceptre sFLR contract (IStakedFlr.getSharesByPooledFlr).
    /// @return outputs The outputs of the operation. Always 1 item.
    ///   0. The current sFLR-per-FLR exchange rate as a Float, i.e.
    ///      `getSharesByPooledFlr(1e18)` divided by 1e18. A value less than 1
    ///      means 1 FLR yields fewer than 1 sFLR share (typical after accrual).
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
