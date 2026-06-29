// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {OperandV2, StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {LibSceptreStakedFlare} from "../sflr/LibSceptreStakedFlare.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

/// @title LibOpSFLRCurrentExchangeRate
/// Implements the `sflrCurrentExchangeRate` externed opcode.
library LibOpSFLRCurrentExchangeRate {
    /// Extern integrity for getting the current exchange rate of sFLR per FLR.
    /// Always requires 0 inputs and produces 1 output.
    function integrity(OperandV2, uint256, uint256) internal pure returns (uint256, uint256) {
        return (0, 1);
    }

    /// Extern implementation for reading the current sFLR-per-FLR exchange rate
    /// directly from the Sceptre sFLR contract (IStakedFlr.getSharesByPooledFlr).
    /// The rate is the number of sFLR shares one FLR of pooled liquidity buys;
    /// values less than 1 mean sFLR is more expensive than FLR (i.e. sFLR has
    /// accrued yield). Downstream callers expecting FLR-per-sFLR must take the
    /// reciprocal.
    /// @dev Inputs are unused; integrity enforces 0 inputs.
    /// @return outputs Always 1 item: the current sFLR-per-FLR rate as a Rain
    /// Float (e.g. ~0.877 when 1 FLR buys 0.877 sFLR).
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
