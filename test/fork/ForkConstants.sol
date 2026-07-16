// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Block number used for Flare mainnet fork tests (FtsoRegistry, sflr, LTS, USD price pair).
uint256 constant BLOCK_NUMBER = 31843105;

/// @dev Block number used for Flare mainnet fork tests involving the flrETH contract,
/// which was deployed later than the feeds used by BLOCK_NUMBER.
uint256 constant FLRETH_BLOCK_NUMBER = 37796420;
