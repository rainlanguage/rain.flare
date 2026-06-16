// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {
    LibFlareContractRegistry,
    IFtsoRegistry,
    FLARE_CONTRACT_REGISTRY,
    FTSO_REGISTRY_NAME,
    FTSO_V2_LTS_NAME,
    FEE_CALCULATOR_NAME,
    ContractNotRegistered
} from "src/lib/registry/LibFlareContractRegistry.sol";

uint256 constant BLOCK_NUMBER = 31843105;

/// External wrapper around the internal library getters so that calling them via
/// `this.<fn>()` produces a dedicated external call frame. `vm.expectRevert`
/// asserts the *next call frame* reverts; an inlined internal library call has
/// no frame of its own, so the wrapper is required to observe the revert.
contract LibFlareContractRegistryExternal {
    function getFtsoRegistry() external view returns (address) {
        return address(LibFlareContractRegistry.getFtsoRegistry());
    }

    function getFtsoV2LTS() external view returns (address) {
        return address(LibFlareContractRegistry.getFtsoV2LTS());
    }

    function getFeeCalculator() external view returns (address) {
        return address(LibFlareContractRegistry.getFeeCalculator());
    }
}

contract LibFlareContractRegistryTest is Test {
    LibFlareContractRegistryExternal internal external_ = new LibFlareContractRegistryExternal();

    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testGetFtsoRegistry() external view {
        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
        assertEq(address(ftsoRegistry), address(0x13DC2b5053857AE17a4f95aFF55530b267F3E040));
    }

    /// When the Flare contract registry resolves the FtsoRegistry name to
    /// address(0) (the documented not-found sentinel), getFtsoRegistry MUST
    /// revert with the specific ContractNotRegistered error rather than
    /// returning a zero-typed handle. Removing the guard in the library makes
    /// this test fail (the getter would return address(0) instead of
    /// reverting).
    function testGetFtsoRegistryZeroAddressReverts() external {
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(FLARE_CONTRACT_REGISTRY.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            abi.encode(address(0))
        );
        vm.expectRevert(abi.encodeWithSelector(ContractNotRegistered.selector, FTSO_REGISTRY_NAME));
        external_.getFtsoRegistry();
    }

    /// As above, for the FtsoV2 LTS getter.
    function testGetFtsoV2LTSZeroAddressReverts() external {
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(FLARE_CONTRACT_REGISTRY.getContractAddressByName.selector, FTSO_V2_LTS_NAME),
            abi.encode(address(0))
        );
        vm.expectRevert(abi.encodeWithSelector(ContractNotRegistered.selector, FTSO_V2_LTS_NAME));
        external_.getFtsoV2LTS();
    }

    /// As above, for the FeeCalculator getter.
    function testGetFeeCalculatorZeroAddressReverts() external {
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(FLARE_CONTRACT_REGISTRY.getContractAddressByName.selector, FEE_CALCULATOR_NAME),
            abi.encode(address(0))
        );
        vm.expectRevert(abi.encodeWithSelector(ContractNotRegistered.selector, FEE_CALCULATOR_NAME));
        external_.getFeeCalculator();
    }
}
