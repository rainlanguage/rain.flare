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
    /// @dev Propagates all reverts from LibOpFtsoCurrentPriceUsd (InactiveFtso,
    /// PriceNotFinalized, InconsistentFtso, StalePrice, DecimalsTooLarge) for
    /// both price fetches. Additionally reverts via LibDecimalFloat.div if the
    /// second (quote) symbol price is zero. The denominator (symbolB) leg is
    /// fetched first; errors on that leg abort before the numerator fetch.
    /// @param inputs The inputs to the operation.
    ///   0. symbolA — the numerator asset symbol, encoded as an unwrapped
    ///      `IntOrAString` (i.e. a `uint256`).
    ///   1. symbolB — the denominator asset symbol, encoded as an unwrapped
    ///      `IntOrAString` (i.e. a `uint256`).
    ///   2. The timeout in seconds to invalidate prices after if the FTSO stops
    ///      updating for some time.
    /// @return outputs The outputs of the operation.
    ///   0. The derived price symbolA/symbolB as a Float representing the
    ///      base/quote ratio (numeratorPrice / denominatorPrice),
    ///      decimal-exponent encoded.
    function run(OperandV2 operand, StackItem[] memory inputs) internal view returns (StackItem[] memory) {
        uint256 symbolA;
        assembly ("memory-safe") {
            // Advance the pointer past the length slot so the virtual 2-element
            // array starts at inputs[1]=symbolB. Save symbolA so it can be
            // restored for the second fetch.
            inputs := add(inputs, 0x20)
            symbolA := mload(inputs)
            mstore(inputs, 2)
        }
        // symbolB (denominator) is fetched first via the memory-truncation trick
        // above, which exposes [symbolB, timeout] as a 2-element inputs array.
        StackItem[] memory denominatorOutputs = LibOpFtsoCurrentPriceUsd.run(operand, inputs);
        assembly ("memory-safe") {
            // Replace symbolB with symbolA so the second fetch uses symbolA.
            mstore(add(inputs, 0x20), symbolA)
        }
        // symbolA is now at inputs[0]; the second fetch resolves the
        // numerator price.
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
