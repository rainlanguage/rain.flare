// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std-1.16.1/src/Script.sol";

import {FlareFtsoWords} from "../src/concrete/FlareFtsoWords.sol";
import {LibCodeGen} from "rain-sol-codegen-0.1.0/src/lib/LibCodeGen.sol";
import {LibFs} from "rain-sol-codegen-0.1.0/src/lib/LibFs.sol";
import {PARSE_META_BUILD_DEPTH} from "../src/abstract/FlareFtsoSubParser.sol";
import {LibFlareFtsoSubParser} from "../src/lib/parse/LibFlareFtsoSubParser.sol";
import {LibGenParseMeta} from "rain-interpreter-interface-0.1.0/src/lib/codegen/LibGenParseMeta.sol";

contract BuildPointers is Script {
    function buildFlareFtsoWordsPointers() internal {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        string memory name = "FlareFtsoWords";

        LibFs.buildFileForContract(
            vm,
            address(flareFtsoWords),
            name,
            string.concat(
                LibCodeGen.describedByMetaHashConstantString(vm, name),
                LibGenParseMeta.parseMetaConstantString(
                    vm, LibFlareFtsoSubParser.authoringMetaV2(), PARSE_META_BUILD_DEPTH
                ),
                LibCodeGen.subParserWordParsersConstantString(vm, flareFtsoWords),
                LibCodeGen.operandHandlerFunctionPointersConstantString(vm, flareFtsoWords),
                LibCodeGen.integrityFunctionPointersConstantString(vm, flareFtsoWords),
                LibCodeGen.opcodeFunctionPointersConstantString(vm, flareFtsoWords)
            )
        );
    }

    function run() external {
        buildFlareFtsoWordsPointers();
    }
}
