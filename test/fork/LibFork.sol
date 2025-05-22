// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {Vm} from "forge-std/Vm.sol";

library LibFork {
    function rpcUrlFlare(Vm vm) internal view returns (string memory) {
        return vm.envOr("RPC_URL_FLARE_FORK", string("https://rpc.ankr.com/flare"));
    }
}
