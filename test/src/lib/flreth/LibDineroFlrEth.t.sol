// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "../../../../test/fork/LibFork.sol";
import {LibDineroFlrEth, FLRETH_CONTRACT} from "../../../../src/lib/flreth/LibDineroFlrEth.sol";
import {IDineroFlrEth} from "../../../../src/interface/IDineroFlrEth.sol";
import {ZeroFlrEthRate} from "../../../../src/err/ErrFlrEth.sol";

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

    // External wrappers needed so vm.expectRevert captures the outer call frame
    // (not the inner LSTPerToken/tokensPerLST staticcall which returns, not reverts).
    function _callGetETHPerFLRETH18() external {
        LibDineroFlrEth.getETHPerFLRETH18();
    }

    function _callGetFLRETHPerETH18() external {
        LibDineroFlrEth.getFLRETHPerETH18();
    }

    function testGetETHPerFLRETH18RevertsOnZeroRate() external {
        vm.mockCall(
            address(FLRETH_CONTRACT), abi.encodeWithSelector(IDineroFlrEth.LSTPerToken.selector), abi.encode(uint256(0))
        );
        vm.expectRevert(ZeroFlrEthRate.selector);
        this._callGetETHPerFLRETH18();
    }

    function testGetFLRETHPerETH18RevertsOnZeroRate() external {
        vm.mockCall(
            address(FLRETH_CONTRACT),
            abi.encodeWithSelector(IDineroFlrEth.tokensPerLST.selector),
            abi.encode(uint256(0))
        );
        vm.expectRevert(ZeroFlrEthRate.selector);
        this._callGetFLRETHPerETH18();
    }
}
