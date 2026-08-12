// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

/// Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrFlrEth {}

/// Thrown when the flrETH contract returns a zero exchange rate. A zero rate
/// indicates a missing contract (no-code address returns 0) or a bug in the
/// upstream proxy, and must not propagate as a valid price.
error ZeroFlrEthRate();
