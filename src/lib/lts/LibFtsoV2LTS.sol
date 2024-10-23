// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.19;

import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {FtsoV2Interface} from "flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {StalePrice} from "../../err/ErrFtso.sol";
import {IFeeCalculator} from "flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";

/// @dev FLR/USD feed ID.
bytes21 constant FLR_USD_FEED_ID = 0x01464c522f55534400000000000000000000000000;

/// @dev SGB/USD feed ID.
bytes21 constant SGB_USD_FEED_ID = 0x015347422f55534400000000000000000000000000;

/// @dev BTC/USD feed ID.
bytes21 constant BTC_USD_FEED_ID = 0x014254432f55534400000000000000000000000000;

/// @dev XRP/USD feed ID.
bytes21 constant XRP_USD_FEED_ID = 0x015852502f55534400000000000000000000000000;

/// @dev LTC/USD feed ID.
bytes21 constant LTC_USD_FEED_ID = 0x014c54432f55534400000000000000000000000000;

/// @dev XLM/USD feed ID.
bytes21 constant XLM_USD_FEED_ID = 0x01584c4d2f55534400000000000000000000000000;

/// @dev DOGE/USD feed ID.
bytes21 constant DOGE_USD_FEED_ID = 0x01444f47452f555344000000000000000000000000;

/// @dev ADA/USD feed ID.
bytes21 constant ADA_USD_FEED_ID = 0x014144412f55534400000000000000000000000000;

/// @dev ALGO/USD feed ID.
bytes21 constant ALGO_USD_FEED_ID = 0x01414c474f2f555344000000000000000000000000;

/// @dev ETH/USD feed ID.
bytes21 constant ETH_USD_FEED_ID = 0x014554482f55534400000000000000000000000000;

library LibFtsoV2LTS {
    function ftsoV2LTSGetFeed(bytes21 feedId, uint256 timeout) internal returns (uint256) {
        // Fetch the FTSO from the registry.
        FtsoV2Interface ftsoRegistry = LibFlareContractRegistry.getFtsoV2LTS();
        IFeeCalculator feeCalculator = LibFlareContractRegistry.getFeeCalculator();

        bytes21[] memory feedIds;
        assembly ("memory-safe") {
            feedIds := mload(0x40)
            mstore(0x40, add(feedIds, 0x40))
            mstore(feedIds, 1)
            mstore(add(feedIds, 0x20), feedId)
        }
        uint256 fee = feeCalculator.calculateFeeByIds(feedIds);

        (uint256 value, uint64 timestamp) = ftsoRegistry.getFeedByIdInWei{value: fee}(feedId);

        // Handle stale prices.
        //slither-disable-next-line timestamp
        if (block.timestamp > timestamp + timeout) {
            revert StalePrice(timestamp, timeout);
        }

        return value;
    }
}
