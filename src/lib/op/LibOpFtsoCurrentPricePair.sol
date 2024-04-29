// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {
    LibFixedPointDecimalArithmeticOpenZeppelin,
    Math
} from "rain.math.fixedpoint/lib/LibFixedPointDecimalArithmeticOpenZeppelin.sol";
import {LibOpFtsoCurrentPriceUsd} from "./LibOpFtsoCurrentPriceUsd.sol";

/// @title LibOpFtsoCurrentPricePair
/// Implements the `ftsoCurrentPricePair` externed opcode.
library LibOpFtsoCurrentPricePair {
    /// Extern integrity for the process of converting two symbols to a derived
    /// price via their respective FTSOs. Always requires 3 inputs and produces
    /// 1 output.
    function integrity(Operand, uint256, uint256) internal pure returns (uint256, uint256) {
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
    ///   0. The derived price of the two assets, normalized to 18 decimals.
    function run(Operand operand, uint256[] memory inputs) internal view returns (uint256[] memory) {
        uint256 symbolA;
        assembly ("memory-safe") {
            // Truncating from 3 inputs to 2, so we can forward directly to the
            // `ftsoCurrentPriceUsd` opcode.
            inputs := add(inputs, 0x20)
            symbolA := mload(inputs)
            mstore(inputs, 2)
        }
        uint256[] memory outputsB = LibOpFtsoCurrentPriceUsd.run(operand, inputs);
        assembly ("memory-safe") {
            mstore(add(inputs, 0x20), symbolA)
        }
        uint256[] memory outputsA = LibOpFtsoCurrentPriceUsd.run(operand, inputs);

        uint256 priceA18;
        uint256 priceB18;
        assembly ("memory-safe") {
            priceA18 := mload(add(outputsA, 0x20))
            priceB18 := mload(add(outputsB, 0x20))
        }

        uint256 pricePair18 =
            LibFixedPointDecimalArithmeticOpenZeppelin.fixedPointDiv(priceA18, priceB18, Math.Rounding.Down);

        // Repurpose one of the inner outputs arrays to return the derived price.
        assembly ("memory-safe") {
            mstore(add(outputsA, 0x20), pricePair18)
        }
        return outputsA;
    }
}
