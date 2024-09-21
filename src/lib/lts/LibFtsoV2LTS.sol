// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {FtsoV2Interface} from "flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {StalePrice} from "../../err/ErrFtso.sol";
import {IFeeCalculator} from "flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";

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
