// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IStakedFlr} from "../../interface/IStakedFlr.sol";

/// @dev Immutable upgradeable proxy contract to the sFLR contract.
IStakedFlr constant SFLR_CONTRACT = IStakedFlr(address(0x12e605bc104e93B45e1aD99F9e555f659051c2BB));

library LibSceptreStakedFlare {
    /// Fixed 18 decimal place ratio of sFLR to FLR.
    /// For each 1e18 FLR, this is how many sFLR are minted.
    function getSFLRPerFLR18() internal view returns (uint256) {
        return SFLR_CONTRACT.getSharesByPooledFlr(1e18);
    }
}
