// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IGovernedFeeCalculator {
    /// @notice Proposes setting the default fee charged per feed read.
    /// @dev This is a governance-gated call: invoking it only queues the
    /// proposal. It must be re-executed via IGoverned.executeGovernanceCall
    /// after the timelock expires before it takes effect.
    /// @param fee The new default fee in wei of native FLR per feed read.
    function setDefaultFee(uint256 fee) external;

    /// @notice Proposes per-feed fee overrides for the given feed IDs.
    /// @dev This is a governance-gated call: invoking it only queues the
    /// proposal. It must be re-executed via IGoverned.executeGovernanceCall
    /// after the timelock expires before it takes effect.
    /// @param feeds Array of bytes21 Flare V2 feed IDs to assign fees to.
    /// @param fees Array of fees in wei of native FLR per read, parallel to
    /// feeds. Reverts if feeds.length != fees.length.
    function setFeedsFees(bytes21[] memory feeds, uint256[] memory fees) external;
}
