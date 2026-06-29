// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {OperandV2, StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {LibFtsoCurrentPriceUsd} from "../price/LibFtsoCurrentPriceUsd.sol";
import {DecimalsTooLarge} from "../../err/ErrFtso.sol";

import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

/// @title LibOpFtsoCurrentPriceUsd
/// Implements the `ftsoCurrentPriceUsd` externed opcode.
library LibOpFtsoCurrentPriceUsd {
    using LibIntOrAString for IntOrAString;

    /// Extern integrity for the process of converting a symbol to a USD price
    /// via an FTSO. Always requires 2 inputs and produces 1 output.
    function integrity(OperandV2, uint256, uint256) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// Extern implementation for the process of converting a symbol to a USD
    /// price via an FTSO. Includes a timeout to prevent stale prices.
    /// Flare Network maintains a registry of contracts with a root at a known
    /// address. This registry is used to find the FTSO contract for the symbol
    /// and then the price is fetched from the FTSO. The price is returned as a
    /// Rain Float, normalized from the FTSO's native decimals.
    /// @dev Propagates InactiveFtso, PriceNotFinalized, InconsistentFtso, and
    /// StalePrice from LibFtsoCurrentPriceUsd. Additionally reverts with
    /// DecimalsTooLarge if the FTSO reports more than 255 decimals.
    /// @param inputs The inputs to the operation. Always 2 items.
    ///   0. The symbol of the asset to fetch the price of, encoded as an
    ///      unwrapped `IntOrAString` (i.e. a `uint256`).
    ///   1. The timeout in seconds to invalidate prices after if the FTSO stops
    ///      updating for some time.
    /// @return outputs The outputs of the operation. Always 1 item.
    ///   0. The price of the asset in USD as a Rain Float.
    function run(OperandV2, StackItem[] memory inputs) internal view returns (StackItem[] memory) {
        IntOrAString symbol;
        Float timeout;
        assembly ("memory-safe") {
            symbol := mload(add(inputs, 0x20))
            timeout := mload(add(inputs, 0x40))
        }

        (uint256 price, uint256 decimals) = LibFtsoCurrentPriceUsd.ftsoCurrentPriceUsd(
            symbol.toStringV3(), LibDecimalFloat.toFixedDecimalLossless(timeout, 0)
        );
        if (decimals > type(uint8).max) {
            revert DecimalsTooLarge(decimals);
        }
        // Check above ensures safe downcast.
        //forge-lint: disable-next-line(unsafe-typecast)
        Float priceFloat = LibDecimalFloat.fromFixedDecimalLosslessPacked(price, uint8(decimals));

        StackItem[] memory outputs;
        assembly ("memory-safe") {
            outputs := mload(0x40)
            mstore(0x40, add(outputs, 0x40))

            mstore(outputs, 1)
            mstore(add(outputs, 0x20), priceFloat)
        }
        return outputs;
    }
}
