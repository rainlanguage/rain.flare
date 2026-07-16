// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {InactiveFtso, PriceNotFinalized, StalePrice, InconsistentFtso, DecimalsTooLarge} from "../../err/ErrFtso.sol";
import {IFtso} from "../../vendor/flare-smart-contracts/userInterfaces/IFtso.sol";

library LibFtsoCurrentPriceUsd {
    /// @notice Fetches the current FTSO USD price for a symbol and returns the
    /// raw price together with its native decimal count. The caller is
    /// responsible for normalising to 18 decimals.
    /// @dev Reverts with InactiveFtso if the FTSO is not active.
    /// Reverts with PriceNotFinalized if the finalization type is not
    /// WEIGHTED_MEDIAN or TRUSTED_ADDRESSES.
    /// Reverts with InconsistentFtso if the two price reads return different
    /// values (indicates an FTSO bug).
    /// Reverts with DecimalsTooLarge if the FTSO reports a decimal count that
    /// does not fit in uint8.
    /// Reverts with StalePrice(priceTimestamp, timeout) if the price is older
    /// than timeout seconds.
    /// @param symbol The FTSO symbol string (e.g. "FLR", "ETH").
    /// @param timeout Max age in seconds; prices older than this revert.
    /// @return price The raw FTSO price in the FTSO's native unit.
    /// @return decimals The decimal precision of the returned price (typically
    /// 5 for Flare FTSO v1, but not guaranteed).
    function ftsoCurrentPriceUsd(string memory symbol, uint256 timeout) internal view returns (uint256, uint8) {
        // Fetch the FTSO from the registry.
        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
        IFtso ftso = ftsoRegistry.getFtsoBySymbol(symbol);

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

        // There are other fallback finalization modes, but weighted median and
        // trusted addresses are the only ones that don't imply the price was
        // simply copied from an earlier epoch.
        if (!(priceFinalizationType == IFtso.PriceFinalizationType.WEIGHTED_MEDIAN
                    || priceFinalizationType == IFtso.PriceFinalizationType.TRUSTED_ADDRESSES)) {
            revert PriceNotFinalized(priceFinalizationType);
        }

        // We need the decimals, which we can't get from the current price
        // details, so that we can do the price normalization.
        (uint256 price1, uint256 priceTimestamp1, uint256 decimals) = ftso.getCurrentPriceWithDecimals();

        // This should never happen, it indicates a bug in the FTSO.
        if (price != price1 || priceTimestamp != priceTimestamp1) {
            revert InconsistentFtso();
        }

        if (decimals > type(uint8).max) {
            revert DecimalsTooLarge(decimals);
        }

        // Handle stale prices.
        //slither-disable-next-line timestamp
        if (block.timestamp > priceTimestamp + timeout) {
            revert StalePrice(priceTimestamp, timeout);
        }

        // Guard above ensures safe downcast.
        //forge-lint: disable-next-line(unsafe-typecast)
        return (price, uint8(decimals));
    }
}
