// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Test} from "forge-std/Test.sol";
import {
    FlareFtsoWords,
    INTEGRITY_FUNCTION_POINTERS,
    SUB_PARSER_OPERAND_HANDLERS,
    OPCODE_FUNCTION_POINTERS,
    SUB_PARSER_WORD_PARSERS,
    SUB_PARSER_PARSE_META,
    AuthoringMetaV2
} from "src/concrete/FlareFtsoWords.sol";
import {LibParseMeta} from "rain.interpreter/lib/parse/LibParseMeta.sol";
import {LibFlareFtsoSubParser} from "src/lib/parse/LibFlareFtsoSubParser.sol";

contract FlareFtsoWordsPointersTest is Test {
    function testIntegrityPointers() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertEq(INTEGRITY_FUNCTION_POINTERS, flareFtsoWords.buildIntegrityFunctionPointers());
    }

    function testOpcodePointers() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertEq(OPCODE_FUNCTION_POINTERS, flareFtsoWords.buildOpcodeFunctionPointers());
    }

    function testSubParserWordParsers() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertEq(SUB_PARSER_WORD_PARSERS, flareFtsoWords.buildSubParserWordParsers());
    }

    function testSubParserOperandHandlers() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertEq(SUB_PARSER_OPERAND_HANDLERS, flareFtsoWords.buildSubParserOperandHandlers());
    }

    function testSubParserParseMeta() external {
        bytes memory authoringMetaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory authoringMeta = abi.decode(authoringMetaBytes, (AuthoringMetaV2[]));
        bytes memory expected = LibParseMeta.buildParseMetaV2(authoringMeta, 2);
        assertEq(SUB_PARSER_PARSE_META, expected);
    }
}
