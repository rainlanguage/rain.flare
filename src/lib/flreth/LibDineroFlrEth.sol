// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IDineroFlrEth} from "../../interface/IDineroFlrEth.sol";

IDineroFlrEth constant FLRETH_CONTRACT = IDineroFlrEth(address(0x26A1faB310bd080542DC864647d05985360B16A5));

library LibDineroFlrEth {
    /// Fixed 18 decimal place ratio of ETH per FLRETH.
    /// For each 1e18 FLRETH, this is how many ETH are deposited.
    function getETHPerFLRETH18() internal view returns (uint256) {
        return FLRETH_CONTRACT.LSTPerToken();
    }

    /// Fixed 18 decimal place ratio of FLRETH per ETH.
    /// For each 1e18 ETH, this is how many FLRETH are minted.
    function getFLRETHPerETH18() internal view returns (uint256) {
        return FLRETH_CONTRACT.tokensPerLST();
    }
}
