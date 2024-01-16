// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Vm} from "forge-std/Vm.sol";

library LibFork {
    function rpcUrlFlare(Vm vm) internal view returns (string memory) {
        return vm.envString("RPC_URL_FLARE");
    }
}