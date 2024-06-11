// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Script} from "forge-std/Script.sol";

import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {LibCodeGen} from "rain.sol.codegen/lib/LibCodeGen.sol";
import {LibFs} from "rain.sol.codegen/lib/LibFs.sol";

contract BuildPointers is Script {

    function buildFlareFtsoWordsPointers() internal {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        string memory name = "FlareFtsoWords";

        LibFs.buildFileForContract(
            vm,
            address(flareFtsoWords),
            name,
            LibCodeGen.describedByMetaHashConstantString(vm, name)
        );
    }

    function run() external {
        buildFlareFtsoWordsPointers();
    }

}