// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Operand} from "rain.interpreter.interface/interface/deprecated/IInterpreterV2.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/lib/LibIntOrAString.sol";
import {LibFtsoCurrentPriceUsd} from "../price/LibFtsoCurrentPriceUsd.sol";

/// @title LibOpFtsoCurrentPriceUsd
/// Implements the `ftsoCurrentPriceUsd` externed opcode.
library LibOpFtsoCurrentPriceUsd {
    using LibIntOrAString for IntOrAString;

    /// Extern integrity for the process of converting a symbol to a USD price
    /// via an FTSO. Always requires 2 inputs and produces 1 output.
    function integrity(Operand, uint256, uint256) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// Extern implementation for the process of converting a symbol to a USD
    /// price via an FTSO. Includes a timeout to prevent stale prices.
    /// Flare Network maintains a registry of contracts with a root at a known
    /// address. This registry is used to find the FTSO contract for the symbol
    /// and then the price is fetched from the FTSO. As the price has its own
    /// decimals, it is converted to 18 decimals to be compatible with general
    /// DeFi conventions including those used by rain. The overall process aims
    /// to be safe and simple, handling as many of the internal implementation
    /// details of FTSOs for the rainlang author as possible.
    /// @param inputs The inputs to the operation. Always 2 items.
    ///   0. The symbol of the asset to fetch the price of, encoded as an
    ///      unwrapped `IntOrAString` (i.e. a `uint256`).
    ///   1. The timeout in seconds to invalidate prices after if the FTSO stops
    ///      updating for some time.
    /// @return outputs The outputs of the operation. Always 1 item.
    ///   0. The price of the asset in USD, normalized to 18 decimals.
    function run(Operand, uint256[] memory inputs) internal view returns (uint256[] memory) {
        IntOrAString symbol;
        uint256 timeout;
        assembly ("memory-safe") {
            symbol := mload(add(inputs, 0x20))
            timeout := mload(add(inputs, 0x40))
        }

        uint256 price18 = LibFtsoCurrentPriceUsd.ftsoCurrentPriceUsd(symbol.toString(), timeout);

        uint256[] memory outputs;
        assembly ("memory-safe") {
            outputs := mload(0x40)
            mstore(0x40, add(outputs, 0x40))

            mstore(outputs, 1)
            mstore(add(outputs, 0x20), price18)
        }
        return outputs;
    }
}
