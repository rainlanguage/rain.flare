// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IGovernedFeeCalculator {
    /// @notice Proposes a new default fee (native FLR wei) charged per feed read.
    /// @dev Governance-gated and timelocked: the change only takes effect after
    /// re-execution via IGoverned.executeGovernanceCall once the timelock elapses.
    /// @param fee The default fee in native FLR wei.
    function setDefaultFee(uint256 fee) external;

    /// @notice Proposes per-feed fee overrides.
    /// @dev Governance-gated and timelocked (see setDefaultFee). `feeds` and `fees`
    /// are positional pairs and MUST be equal length.
    /// @param feeds Feed IDs (bytes21) to set fees for.
    /// @param fees Per-feed fees in native FLR wei, aligned to `feeds`.
    function setFeedsFees(bytes21[] memory feeds, uint256[] memory fees) external;
}
