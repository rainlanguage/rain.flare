// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

import {Script} from "forge-std/Script.sol";
import {FlareFtsoWords} from "../src/concrete/FlareFtsoWords.sol";
import {IMetaBoardV1} from "rain.metadata/interface/IMetaBoardV1.sol";
import {LibDescribedByMeta} from "rain.metadata/lib/LibDescribedByMeta.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");
        bytes memory subParserDescribedByMeta = vm.readFileBinary("meta/FlareFtsoWords.rain.meta");
        IMetaBoardV1 metaboard = IMetaBoardV1(vm.envAddress("DEPLOY_METABOARD_ADDRESS"));

        vm.startBroadcast(deployerPrivateKey);
        FlareFtsoWords subParser = new FlareFtsoWords();
        LibDescribedByMeta.emitForDescribedAddress(metaboard, subParser, subParserDescribedByMeta);

        vm.stopBroadcast();
    }
}
