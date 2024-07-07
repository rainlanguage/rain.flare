// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {LibFlareContractRegistry, IFtsoRegistry} from "src/lib/registry/LibFlareContractRegistry.sol";

uint256 constant BLOCK_NUMBER = 21862503;

contract LibFlareContractRegistryTest is Test {
    constructor() {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testGetFtsoRegistry() external {
        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
        assertEq(address(ftsoRegistry), address(0x13DC2b5053857AE17a4f95aFF55530b267F3E040));
    }
}
