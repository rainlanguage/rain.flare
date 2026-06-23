// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {InactiveFtso, PriceNotFinalized, StalePrice, InconsistentFtso} from "../../err/ErrFtso.sol";
import {IFtso} from "../../vendor/flare-smart-contracts/userInterfaces/IFtso.sol";

library LibFtsoCurrentPriceUsd {
    /// Fetches the current USD price and its native decimals for an FTSO symbol
    /// from the Flare contract registry. Reverts InactiveFtso if the FTSO is not
    /// active, PriceNotFinalized if the price was not finalized by weighted
    /// median or trusted addresses, InconsistentFtso if the FTSO's two price
    /// reads disagree, and StalePrice if the price is older than `timeout`
    /// seconds. The returned price is NOT normalized; the returned `decimals` are
    /// whatever the FTSO reports and are NOT bounds-checked here (callers MUST
    /// guard against oversized decimals before scaling).
    /// @param symbol The FTSO asset symbol to price, e.g. "ETH".
    /// @param timeout Max age in seconds before the price is considered stale.
    /// @return price The FTSO USD price, scaled by 10**decimals.
    /// @return decimals The number of decimals the FTSO uses for `price`.
    function ftsoCurrentPriceUsd(string memory symbol, uint256 timeout) internal view returns (uint256, uint256) {
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

        // Handle stale prices.
        //slither-disable-next-line timestamp
        if (block.timestamp > priceTimestamp + timeout) {
            revert StalePrice(priceTimestamp, timeout);
        }

        return (price, decimals);
    }
}
