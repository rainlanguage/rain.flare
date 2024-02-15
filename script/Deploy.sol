// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {Script} from "forge-std/Script.sol";
import {FlareFtsoWords} from "../src/concrete/FlareFtsoWords.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        vm.startBroadcast(deployerPrivateKey);
        new FlareFtsoWords();
        vm.stopBroadcast();
    }
}
