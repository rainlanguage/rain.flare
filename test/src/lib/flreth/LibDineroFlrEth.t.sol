// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
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
}
