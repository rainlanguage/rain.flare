// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.19;

import {IFtso} from "flare-smart-contracts/userInterfaces/IFtso.sol";

/// Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrFtso {}

/// Thrown when an FTSO that we are reading a price from is not active.
error InactiveFtso();

/// Thrown when an FTSO that we are reading a price from has not finalized the
/// price.
/// @param priceFinalizationType The price finalization that the FTSO reported.
error PriceNotFinalized(IFtso.PriceFinalizationType priceFinalizationType);

/// Thrown when an FTSO that we are reading a price from has not updated the
/// price in longer than the timeout.
/// @param timestamp The timestamp of the last price update.
/// @param timeout The timeout in seconds.
error StalePrice(uint256 timestamp, uint256 timeout);

/// Thrown when an FTSO reports values from different methods that MUST agree
/// with each other, but do not.
error InconsistentFtso();
