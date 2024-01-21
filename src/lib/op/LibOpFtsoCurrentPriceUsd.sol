// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Operand} from "rain.interpreter/interface/unstable/IInterpreterV2.sol";
import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {IFtso} from "flare-smart-contracts/userInterfaces/IFtso.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/src/lib/LibIntOrAString.sol";
import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";

import {InactiveFtso, PriceNotFinalized, StalePrice, InconsistentFtso} from "../../err/ErrFtso.sol";

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

        // Fetch the FTSO from the registry.
        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
        IFtso ftso = ftsoRegistry.getFtsoBySymbol(symbol.toString());

        // FTSO can self report whether it is "active" so we require this.
        if (!ftso.active()) {
            revert InactiveFtso();
        }

        // We need the price finalization type, which we can't get from the
        // current price otherwise, so that we can avoid low quality prices.
        (
            uint256 price,
            uint256 priceTimestamp,
            IFtso.PriceFinalizationType priceFinalizationType,
            uint256 lastPriceEpochFinalizationTimestamp,
            IFtso.PriceFinalizationType lastPriceEpochFinalizationType
        ) = ftso.getCurrentPriceDetails();
        (lastPriceEpochFinalizationTimestamp, lastPriceEpochFinalizationType); // Silence unused variable warning.

        // There are other fallback finalization modes, but weighted median is
        // the only completion state that involved a sufficient number of
        // oracles to be considered "trustless".
        if (priceFinalizationType != IFtso.PriceFinalizationType.WEIGHTED_MEDIAN) {
            revert PriceNotFinalized(priceFinalizationType);
        }

        // We need the decimals, which we can't get from the current price
        // details, so that we can do the price normalization.
        (uint256 price1, uint256 priceTimestamp1, uint256 decimals) = ftso.getCurrentPriceWithDecimals();

        // This should never happen, it indicates a bug in the FTSO.
        if (price != price1 || priceTimestamp != priceTimestamp1) {
            revert InconsistentFtso();
        }

        // Handle stale prices.
        //slither-disable-next-line timestamp
        if (block.timestamp > priceTimestamp + timeout) {
            revert StalePrice(priceTimestamp, timeout);
        }

        // Normalize all prices to fixed point 18 decimals.
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
