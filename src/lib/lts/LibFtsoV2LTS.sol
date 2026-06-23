// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

//forge-lint: disable-next-line(unused-import)
import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {FtsoV2Interface} from "../../vendor/flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {StalePrice} from "../../err/ErrFtso.sol";
import {IFeeCalculator} from "../../vendor/flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";

/// @dev FTSO feed IDs.
/// https://dev.flare.network/ftso/feeds

/// @dev 0 FLR/USD feed ID.
bytes21 constant FLR_USD_FEED_ID = 0x01464c522f55534400000000000000000000000000;

/// @dev 1 SGB/USD feed ID.
bytes21 constant SGB_USD_FEED_ID = 0x015347422f55534400000000000000000000000000;

/// @dev 2 BTC/USD feed ID.
bytes21 constant BTC_USD_FEED_ID = 0x014254432f55534400000000000000000000000000;

/// @dev 3 XRP/USD feed ID.
bytes21 constant XRP_USD_FEED_ID = 0x015852502f55534400000000000000000000000000;

/// @dev 4 LTC/USD feed ID.
bytes21 constant LTC_USD_FEED_ID = 0x014c54432f55534400000000000000000000000000;

/// @dev 5 XLM/USD feed ID.
bytes21 constant XLM_USD_FEED_ID = 0x01584c4d2f55534400000000000000000000000000;

/// @dev 6 DOGE/USD feed ID.
bytes21 constant DOGE_USD_FEED_ID = 0x01444f47452f555344000000000000000000000000;

/// @dev 7 ADA/USD feed ID.
bytes21 constant ADA_USD_FEED_ID = 0x014144412f55534400000000000000000000000000;

/// @dev 8 ALGO/USD feed ID.
bytes21 constant ALGO_USD_FEED_ID = 0x01414c474f2f555344000000000000000000000000;

/// @dev 9 ETH/USD feed ID.
bytes21 constant ETH_USD_FEED_ID = 0x014554482f55534400000000000000000000000000;

/// @dev 10 FIL/USD feed ID.
bytes21 constant FIL_USD_FEED_ID = 0x0146494c2f55534400000000000000000000000000;

/// @dev 11 ARB/USD feed ID.
bytes21 constant ARB_USD_FEED_ID = 0x014152422f55534400000000000000000000000000;

/// @dev 12 AVAX/USD feed ID.
bytes21 constant AVAX_USD_FEED_ID = 0x01415641582f555344000000000000000000000000;

/// @dev 13 BNB/USD feed ID.
bytes21 constant BNB_USD_FEED_ID = 0x01424e422f55534400000000000000000000000000;

/// @dev 14 POL/USD feed ID.
bytes21 constant POL_USD_FEED_ID = 0x01504f4c2f55534400000000000000000000000000;

/// @dev 15 SOL/USD feed ID.
bytes21 constant SOL_USD_FEED_ID = 0x01534f4c2f55534400000000000000000000000000;

/// @dev 16 USDC/USD feed ID.
bytes21 constant USDC_USD_FEED_ID = 0x01555344432f555344000000000000000000000000;

/// @dev 17 USDT/USD feed ID.
bytes21 constant USDT_USD_FEED_ID = 0x01555344542f555344000000000000000000000000;

/// @dev 18 XDC/USD feed ID.
bytes21 constant XDC_USD_FEED_ID = 0x015844432f55534400000000000000000000000000;

/// @dev 19 TRX/USD feed ID.
bytes21 constant TRX_USD_FEED_ID = 0x015452582f55534400000000000000000000000000;

/// @dev 52 JOULE/USD feed ID.
bytes21 constant JOULE_USD_FEED_ID = 0x014a4f554c452f5553440000000000000000000000;

library LibFtsoV2LTS {
    /// @dev Fetches the value of a feed from the FTSO using V2 LTS.
    /// Note that this is NOT a view function and will cost gas if the FTSO has
    /// a fee set.
    //forge-lint: disable-next-line(mixed-case-function)
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

        // Handle stale prices. Subtraction avoids checked-arithmetic overflow
        // when timeout is near type(uint256).max (which means "never stale").
        //slither-disable-next-line timestamp
        if (block.timestamp > timestamp && block.timestamp - timestamp > timeout) {
            revert StalePrice(timestamp, timeout);
        }

        return value;
    }
}
