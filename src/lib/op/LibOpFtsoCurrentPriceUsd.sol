// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Operand} from "rain.interpreter/interface/unstable/IInterpreterV2.sol";
import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {IFtso} from "flare-smart-contracts/userInterfaces/IFtso.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/src/lib/LibIntOrAString.sol";
import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";

import {InactiveFtso, PriceNotFinalized, StalePrice} from "../../err/ErrFtso.sol";

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
    /// to be as conservative as possible, reverting if there is any doubt about
    /// the validity of the price.
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

        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
        IFtso ftso = ftsoRegistry.getFtsoBySymbol(symbol.toString());

        if (!ftso.active()) {
            revert InactiveFtso();
        }

        (,, IFtso.PriceFinalizationType priceFinalizationType,,) = ftso.getCurrentPriceDetails();
        if (priceFinalizationType != IFtso.PriceFinalizationType.WEIGHTED_MEDIAN) {
            revert PriceNotFinalized(priceFinalizationType);
        }

        (uint256 price, uint256 priceTimestamp, uint256 decimals) = ftso.getCurrentPriceWithDecimals();

        if (block.timestamp > priceTimestamp + timeout) {
            revert StalePrice(priceTimestamp, timeout);
        }

        // Flags are 0 i.e. round down and don't saturate (error instead).
        uint256 price18 = LibFixedPointDecimalScale.scale18(price, decimals, 0);

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
