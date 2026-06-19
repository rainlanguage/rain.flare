// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {LibDineroFlrEth} from "src/lib/flreth/LibDineroFlrEth.sol";

uint256 constant BLOCK_NUMBER = 37796420;

contract LibDineroFlrEthTest is Test {
    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testGetETHPerFLRETH18() external view {
        uint256 rate18 = LibDineroFlrEth.getETHPerFLRETH18();
        assertEq(rate18, 1.011016974180723407e18);
    }

    function testGetFLRETHPerETH18() external view {
        uint256 rate18 = LibDineroFlrEth.getFLRETHPerETH18();
        assertEq(rate18, 0.989103076939285809e18);
    }

    function testFlrEthRateScaleBand() external view {
        uint256 ethPerFlrEth = LibDineroFlrEth.getETHPerFLRETH18();
        assertGe(ethPerFlrEth, 0.1e18, "ETH/flrETH rate below 0.1 -- scale may have changed");
        assertLe(ethPerFlrEth, 10e18, "ETH/flrETH rate above 10 -- scale may have changed");

        uint256 flrEthPerEth = LibDineroFlrEth.getFLRETHPerETH18();
        assertGe(flrEthPerEth, 0.1e18, "flrETH/ETH rate below 0.1 -- scale may have changed");
        assertLe(flrEthPerEth, 10e18, "flrETH/ETH rate above 10 -- scale may have changed");
    }
}
