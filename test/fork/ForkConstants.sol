// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Canonical Flare mainnet block for registry, FTSO, sFLR, and LTS tests.
uint256 constant BLOCK_NUMBER = 31843105;

/// @dev Canonical Flare mainnet block for the dinero flrETH tests, which
/// exercise state at a different height than the FTSO/sFLR suite.
uint256 constant FLRETH_BLOCK_NUMBER = 37796420;
