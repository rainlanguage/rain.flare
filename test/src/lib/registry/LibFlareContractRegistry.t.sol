// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {
    LibFlareContractRegistry,
    IFtsoRegistry,
    FTSO_REGISTRY_NAME,
    FTSO_V2_LTS_NAME,
    FEE_CALCULATOR_NAME
} from "src/lib/registry/LibFlareContractRegistry.sol";

uint256 constant BLOCK_NUMBER = 31843105;

contract LibFlareContractRegistryTest is Test {
    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testRegistryNameLiterals() external pure {
        assertEq(FTSO_REGISTRY_NAME, "FtsoRegistry");
        assertEq(FTSO_V2_LTS_NAME, "FtsoV2");
        assertEq(FEE_CALCULATOR_NAME, "FeeCalculator");
    }

    function testGetFtsoRegistry() external view {
        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
        assertEq(address(ftsoRegistry), address(0x13DC2b5053857AE17a4f95aFF55530b267F3E040));
    }
}
