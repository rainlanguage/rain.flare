// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {IFtso} from "flare-smart-contracts/userInterfaces/IFtso.sol";

/// Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrFtso {}

/// Thrown when an FTSO that we are reading a price from is not active.
error InactiveFtso();

/// Thrown when an FTSO that we are reading a price from has not finalized the
/// price, or the price is not finalized in a way that we can use
/// (e.g. it is falling back to "trusted" price providers).
/// @param priceFinalizationType The price finalization that the FTSO reported.
error PriceNotFinalized(IFtso.PriceFinalizationType priceFinalizationType);

/// Thrown when an FTSO that we are reading a price from has not updated the
/// price in longer than the timeout.
/// @param timestamp The timestamp of the last price update.
/// @param timeout The timeout in seconds.
error StalePrice(uint256 timestamp, uint256 timeout);
