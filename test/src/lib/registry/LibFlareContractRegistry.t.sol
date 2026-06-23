// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {LibFlareContractRegistry, IFtsoRegistry} from "src/lib/registry/LibFlareContractRegistry.sol";
import {FtsoV2Interface} from "src/vendor/flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {IFeeCalculator} from "src/vendor/flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";

uint256 constant BLOCK_NUMBER = 31843105;

contract LibFlareContractRegistryTest is Test {
    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testGetFtsoRegistry() external view {
        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
        assertEq(address(ftsoRegistry), address(0x13DC2b5053857AE17a4f95aFF55530b267F3E040));
    }

    function testGetFtsoV2LTS() external view {
        FtsoV2Interface ftsoV2 = LibFlareContractRegistry.getFtsoV2LTS();
        assertTrue(address(ftsoV2) != address(0));
    }

    function testGetFeeCalculator() external view {
        IFeeCalculator feeCalculator = LibFlareContractRegistry.getFeeCalculator();
        assertTrue(address(feeCalculator) != address(0));
    }
}
