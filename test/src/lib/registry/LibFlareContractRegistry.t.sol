// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {LibFlareContractRegistry, IFtsoRegistry} from "src/lib/registry/LibFlareContractRegistry.sol";

contract LibFlareContractRegistryTest is Test {

    uint256 constant BLOCK_NUMBER = 18262564;

    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testGetFtsoRegistry() external {
        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
    }
}