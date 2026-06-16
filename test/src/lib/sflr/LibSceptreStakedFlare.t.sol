// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {LibSceptreStakedFlare, SFLR_CONTRACT} from "src/lib/sflr/LibSceptreStakedFlare.sol";
import {IStakedFlr} from "src/interface/IStakedFlr.sol";
import {ZeroSFLRRate} from "src/err/ErrFtso.sol";

uint256 constant BLOCK_NUMBER = 31843105;

contract LibSceptreStakedFlareTest is Test {
    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function callGetSFLRPerFLR18() external view returns (uint256) {
        return LibSceptreStakedFlare.getSFLRPerFLR18();
    }

    function testGetSFLRPerFLR18() external view {
        uint256 rate18 = LibSceptreStakedFlare.getSFLRPerFLR18();
        assertEq(rate18, 0.877817288626455057e18);
    }

    function testGetSFLRPerFLR18ZeroReverts() external {
        vm.mockCall(
            address(SFLR_CONTRACT),
            abi.encodeWithSelector(IStakedFlr.getSharesByPooledFlr.selector),
            abi.encode(uint256(0))
        );
        vm.expectRevert(abi.encodeWithSelector(ZeroSFLRRate.selector));
        this.callGetSFLRPerFLR18();
    }
}
