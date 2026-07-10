// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {LibSceptreStakedFlare, SFLR_CONTRACT} from "src/lib/sflr/LibSceptreStakedFlare.sol";
import {IStakedFlr} from "src/interface/IStakedFlr.sol";

uint256 constant BLOCK_NUMBER = 31843105;

contract LibSceptreStakedFlareTest is Test {
    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testGetSFLRPerFLR18() external view {
        uint256 rate18 = LibSceptreStakedFlare.getSFLRPerFLR18();
        assertEq(rate18, 0.877817288626455057e18);
    }

    /// #61 — verifies that getSFLRPerFLR18 passes exactly 1e18 as the argument
    /// to getSharesByPooledFlr. If the library ever passes a different amount the
    /// mock won't intercept and the test will fail.
    function testGetSFLRPerFLR18CallsWith1e18() external {
        vm.mockCall(
            address(SFLR_CONTRACT),
            abi.encodeWithSelector(IStakedFlr.getSharesByPooledFlr.selector, uint256(1e18)),
            abi.encode(uint256(0.9e18))
        );
        assertEq(LibSceptreStakedFlare.getSFLRPerFLR18(), 0.9e18);
    }

    /// #61 — documents that getSFLRPerFLR18 is a pure pass-through for any
    /// non-zero return value (the exact return is forwarded unchanged).
    function testGetSFLRPerFLR18PassesThrough(uint256 rate) external {
        vm.assume(rate > 0);
        vm.mockCall(
            address(SFLR_CONTRACT),
            abi.encodeWithSelector(IStakedFlr.getSharesByPooledFlr.selector, uint256(1e18)),
            abi.encode(rate)
        );
        assertEq(LibSceptreStakedFlare.getSFLRPerFLR18(), rate);
    }
}
