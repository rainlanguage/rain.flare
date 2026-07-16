// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "../../../fork/LibFork.sol";
import {
    LibFlareContractRegistry,
    IFtsoRegistry,
    FTSO_REGISTRY_NAME,
    FTSO_V2_LTS_NAME,
    FEE_CALCULATOR_NAME
} from "../../../../src/lib/registry/LibFlareContractRegistry.sol";
import {FtsoV2Interface} from "../../../../src/vendor/flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {IFeeCalculator} from "../../../../src/vendor/flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";
import {BLOCK_NUMBER} from "../../../fork/ForkConstants.sol";

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
        assertEq(address(ftsoV2), address(0xB18d3A5e5A85C65cE47f977D7F486B79F99D3d32));
    }

    function testGetFeeCalculator() external view {
        IFeeCalculator feeCalc = LibFlareContractRegistry.getFeeCalculator();
        assertEq(address(feeCalc), address(0xFDe4f89E6d67ec1a497e1c25944ba5D2d7a36bf3));
    }

    function testRegistryNameLiterals() external pure {
        assertEq(FTSO_REGISTRY_NAME, "FtsoRegistry");
        assertEq(FTSO_V2_LTS_NAME, "FtsoV2");
        assertEq(FEE_CALCULATOR_NAME, "FeeCalculator");
    }
}
