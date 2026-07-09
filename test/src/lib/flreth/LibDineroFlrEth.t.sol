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

    /// The two rates are mathematical inverses: ethPerFLRETH * flrethPerETH ≈ 1e36.
    /// A failed reciprocity check would flag an inverted numerator/denominator mapping.
    /// Note this check alone is symmetric — swapping the two getters leaves the
    /// product unchanged — so direction is pinned by testRateDirection below.
    function testRatesAreReciprocal() external view {
        uint256 ethPerFLRETH = LibDineroFlrEth.getETHPerFLRETH18();
        uint256 flrethPerETH = LibDineroFlrEth.getFLRETHPerETH18();
        assertApproxEqRel(ethPerFLRETH * flrethPerETH, 1e36, 1e15);
    }

    /// Asymmetric direction invariant. FLRETH accrues staking rewards, so on a
    /// live fork each FLRETH is backed by at least 1 ETH: ethPerFLRETH >= 1e18
    /// and, reciprocally, flrethPerETH <= 1e18. Swapping the two getters flips
    /// both inequalities, so unlike reciprocity this fails under an inverted
    /// numerator/denominator mapping.
    function testRateDirection() external view {
        assertGe(LibDineroFlrEth.getETHPerFLRETH18(), 1e18);
        assertLe(LibDineroFlrEth.getFLRETHPerETH18(), 1e18);
    }
}
