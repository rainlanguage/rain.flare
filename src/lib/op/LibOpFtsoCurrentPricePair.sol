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
    /// This works by fetching the price of each symbol from its respective FTSO
    /// and then dividing the two prices to get the derived price. All the same
    /// considerations apply as for `ftsoCurrentPriceUsd` for each price fetch,
    /// e.g. stale and non-finalized prices are rejected, etc.
    /// Note that as the price is derived from two FTSOs, it is not a literal
    /// value that any FTSO is reporting, rather it is calculated from separate
    /// values. Notably, and especially if the timeout is long, the two prices
    /// may not be from the same block. This can cause inaccuracies in the
    /// derived price if there has been significant volatility between the two
    /// individual quotes, so SHOULD NOT be relied upon for high precision
    /// calculations.
    /// @param inputs The inputs to the operation.
    ///   0. The symbol of the first asset to fetch the price of, encoded as an
    ///      unwrapped `IntOrAString` (i.e. a `uint256`).
    ///   1. The symbol of the second asset to fetch the price of, encoded as an
    ///      unwrapped `IntOrAString` (i.e. a `uint256`).
    ///   2. The timeout in seconds to invalidate prices after if the FTSO stops
    ///      updating for some time.
    /// @return outputs The outputs of the operation.
    ///   0. The derived price of the two assets as a Float representing the
    ///      base/quote ratio (priceA / priceB), decimal-exponent encoded.
    /// @custom:error Reverts with a divide-by-zero panic if the quote (second)
    ///   symbol resolves to a zero price via `LibDecimalFloat.div`. Also
    ///   propagates all `ftsoCurrentPriceUsd` errors for each fetch.
    function run(OperandV2 operand, StackItem[] memory inputs) internal view returns (StackItem[] memory) {
        uint256 symbolA;
        assembly ("memory-safe") {
            // Truncating from 3 inputs to 2, so we can forward directly to the
            // `ftsoCurrentPriceUsd` opcode.
            inputs := add(inputs, 0x20)
            symbolA := mload(inputs)
            mstore(inputs, 2)
        }
        StackItem[] memory outputsB = LibOpFtsoCurrentPriceUsd.run(operand, inputs);
        assembly ("memory-safe") {
            mstore(add(inputs, 0x20), symbolA)
        }
        StackItem[] memory outputsA = LibOpFtsoCurrentPriceUsd.run(operand, inputs);

        Float priceA;
        Float priceB;
        assembly ("memory-safe") {
            priceA := mload(add(outputsA, 0x20))
            priceB := mload(add(outputsB, 0x20))
        }

        Float pricePair = priceA.div(priceB);

        // Repurpose one of the inner outputs arrays to return the derived price.
        assembly ("memory-safe") {
            mstore(add(outputsA, 0x20), pricePair)
        }
        return outputsA;
    }
}
