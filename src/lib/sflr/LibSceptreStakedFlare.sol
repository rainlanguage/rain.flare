// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IStakedFlr} from "../../interface/IStakedFlr.sol";
import {ZeroSFLRRate} from "../../err/ErrFtso.sol";

/// @dev Immutable upgradeable proxy contract to the sFLR contract.
IStakedFlr constant SFLR_CONTRACT = IStakedFlr(address(0x12e605bc104e93B45e1aD99F9e555f659051c2BB));

library LibSceptreStakedFlare {
    /// Fixed 18 decimal place ratio of sFLR to FLR.
    /// For each 1e18 FLR pooled, this is how many sFLR shares it is worth
    /// according to the sFLR contract's current exchange rate.
    //forge-lint: disable-next-line(mixed-case-function)
    function getSFLRPerFLR18() internal view returns (uint256) {
        uint256 rate = SFLR_CONTRACT.getSharesByPooledFlr(1e18);
        if (rate == 0) revert ZeroSFLRRate();
        return rate;
    }
}
