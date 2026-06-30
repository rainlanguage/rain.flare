// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {OperandV2, StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {LibOpFtsoCurrentPriceUsd} from "./LibOpFtsoCurrentPriceUsd.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

/// @title LibOpFtsoCurrentPricePair
/// Implements the `ftsoCurrentPricePair` externed opcode.
library LibOpFtsoCurrentPricePair {
    using LibDecimalFloat for Float;

    /// Extern integrity for the process of converting two symbols to a derived
    /// price via their respective FTSOs. Always requires 3 inputs and produces
    /// 1 output.
    function integrity(OperandV2, uint256, uint256) internal pure returns (uint256, uint256) {
        return (3, 1);
    }

    /// Extern implementation for the process of converting two symbols to a
    /// derived price via their respective FTSOs.
    /// This works by fetching the USD price of each symbol from its respective
    /// FTSO and then dividing the numerator price by the denominator price.
    /// All the same considerations apply as for `ftsoCurrentPriceUsd` for each
    /// price fetch, e.g. stale and non-finalized prices are rejected, etc.
    /// Note that as the price is derived from two FTSOs, it is not a literal
    /// value that any FTSO is reporting, rather it is calculated from separate
    /// values. Notably, and especially if the timeout is long, the two prices
    /// may not be from the same block. This can cause inaccuracies in the
    /// derived price if there has been significant volatility between the two
    /// individual quotes, so SHOULD NOT be relied upon for high precision
    /// calculations.
    /// @param inputs The inputs to the operation.
    ///   0. symbolA — the numerator asset symbol, encoded as an unwrapped
    ///      `IntOrAString` (i.e. a `uint256`).
    ///   1. symbolB — the denominator asset symbol, encoded as an unwrapped
    ///      `IntOrAString` (i.e. a `uint256`).
    ///   2. The timeout in seconds to invalidate prices after if the FTSO stops
    ///      updating for some time.
    /// @return outputs The outputs of the operation.
    ///   0. The derived price symbolA/symbolB, normalized to 18 decimals.
    /// @dev Reverts with `InactiveFtso`, `StalePrice`, or `PriceNotFinalized`
    /// (propagated from `ftsoCurrentPriceUsd`) if either FTSO is unusable.
    /// The denominator (symbolB) is fetched first; errors on that leg abort
    /// before the numerator fetch.  Reverts with `DivisionByZero` (from
    /// `LibDecimalFloat`) if the denominator USD price is zero.
    function run(OperandV2 operand, StackItem[] memory inputs) internal view returns (StackItem[] memory) {
        uint256 symbolA;
        assembly ("memory-safe") {
            // Truncating from 3 inputs to 2, so we can forward directly to the
            // `ftsoCurrentPriceUsd` opcode.
            inputs := add(inputs, 0x20)
            symbolA := mload(inputs)
            mstore(inputs, 2)
        }
        // symbolB (denominator) is fetched first via the memory-truncation trick
        // above, which exposes [symbolB, timeout] as a 2-element inputs array.
        StackItem[] memory denominatorOutputs = LibOpFtsoCurrentPriceUsd.run(operand, inputs);
        assembly ("memory-safe") {
            mstore(add(inputs, 0x20), symbolA)
        }
        StackItem[] memory numeratorOutputs = LibOpFtsoCurrentPriceUsd.run(operand, inputs);

        Float numeratorPrice;
        Float denominatorPrice;
        assembly ("memory-safe") {
            numeratorPrice := mload(add(numeratorOutputs, 0x20))
            denominatorPrice := mload(add(denominatorOutputs, 0x20))
        }

        Float pricePair = numeratorPrice.div(denominatorPrice);

        // Repurpose one of the inner outputs arrays to return the derived price.
        assembly ("memory-safe") {
            mstore(add(numeratorOutputs, 0x20), pricePair)
        }
        return numeratorOutputs;
    }
}
