// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {LibSceptreStakedFlare} from "src/lib/sflr/LibSceptreStakedFlare.sol";

uint256 constant BLOCK_NUMBER = 31843105;

contract LibFlareContractRegistryTest is Test {
    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testGetSFLRPerFLR18() external view {
        uint256 rate18 = LibSceptreStakedFlare.getSFLRPerFLR18();
        assertEq(rate18, 0.877817288626455057e18);
    }
}
