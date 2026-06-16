// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {InactiveFtso, PriceNotFinalized, StalePrice, InconsistentFtso} from "../../err/ErrFtso.sol";
import {IFtso} from "../../vendor/flare-smart-contracts/userInterfaces/IFtso.sol";

library LibFtsoCurrentPriceUsd {
    /// @dev Fetches the current USD price and its native decimals for an FTSO
    /// symbol from the Flare contract registry. The returned price is NOT
    /// normalized; callers MUST normalize to their required precision (e.g. 18
    /// decimals) and MUST guard against unexpectedly large decimals before
    /// scaling (see `DecimalsTooLarge` in the caller).
    /// @param symbol The FTSO asset symbol to price, e.g. "ETH".
    /// @param timeout Max age in seconds before the price is considered stale.
    /// @return price The FTSO USD price, scaled by 10**decimals.
    /// @return decimals The number of decimals the FTSO uses for `price`.
    /// @custom:error InactiveFtso The FTSO reports itself as inactive.
    /// @custom:error PriceNotFinalized The price was not finalized by weighted
    /// median or trusted addresses (other modes copy an earlier epoch).
    /// @custom:error InconsistentFtso The two FTSO reads disagreed on price or
    /// timestamp, indicating a bug in the FTSO.
    /// @custom:error StalePrice The price timestamp is older than `timeout` seconds.
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
