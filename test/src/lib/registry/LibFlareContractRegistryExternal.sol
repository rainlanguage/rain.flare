// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {
    LibFlareContractRegistry,
    IFtsoRegistry
} from "src/lib/registry/LibFlareContractRegistry.sol";

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
