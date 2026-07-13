// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IDineroFlrEth} from "../../interface/IDineroFlrEth.sol";
import {ZeroFlrEthRate} from "../../err/ErrFlrEth.sol";

IDineroFlrEth constant FLRETH_CONTRACT = IDineroFlrEth(address(0x26A1faB310bd080542DC864647d05985360B16A5));

library LibDineroFlrEth {
    /// Fixed 18 decimal place ratio of ETH per FLRETH.
    /// For each 1e18 FLRETH, this is how many ETH are deposited.
    //forge-lint: disable-next-line(mixed-case-function)
    function getETHPerFLRETH18() internal view returns (uint256) {
        uint256 rate = FLRETH_CONTRACT.LSTPerToken();
        if (rate == 0) revert ZeroFlrEthRate();
        return rate;
    }

    /// Fixed 18 decimal place ratio of FLRETH per ETH.
    /// For each 1e18 ETH, this is how many FLRETH are minted.
    //forge-lint: disable-next-line(mixed-case-function)
    function getFLRETHPerETH18() internal view returns (uint256) {
        uint256 rate = FLRETH_CONTRACT.tokensPerLST();
        if (rate == 0) revert ZeroFlrEthRate();
        return rate;
    }
}
