// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    FlareFtsoWords,
    INTEGRITY_FUNCTION_POINTERS,
    SUB_PARSER_OPERAND_HANDLERS,
    OPCODE_FUNCTION_POINTERS,
    SUB_PARSER_WORD_PARSERS,
    SUB_PARSER_PARSE_META,
    AuthoringMetaV2
} from "src/concrete/FlareFtsoWords.sol";
import {LibGenParseMeta} from "rain-interpreter-interface-0.1.0/src/lib/codegen/LibGenParseMeta.sol";
import {LibFlareFtsoSubParser} from "src/lib/parse/LibFlareFtsoSubParser.sol";
import {BYTECODE_HASH} from "src/generated/FlareFtsoWords.pointers.sol";
import {
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD,
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR,
    SUB_PARSER_WORD_SFLR_EXCHANGE_RATE,
    SUB_PARSER_WORD_PARSERS_LENGTH
} from "src/lib/parse/LibFlareFtsoSubParser.sol";
import {
    OPCODE_FTSO_CURRENT_PRICE_USD,
    OPCODE_FTSO_CURRENT_PRICE_PAIR,
    OPCODE_SFLR_CURRENT_EXCHANGE_RATE,
    OPCODE_FUNCTION_POINTERS_LENGTH
} from "src/abstract/FlareFtsoExtern.sol";

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
        assertEq(SUB_PARSER_OPERAND_HANDLERS, flareFtsoWords.buildOperandHandlerFunctionPointers());
    }

    function testSubParserParseMeta() external pure {
        bytes memory authoringMetaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory authoringMeta = abi.decode(authoringMetaBytes, (AuthoringMetaV2[]));
        bytes memory expected = LibGenParseMeta.buildParseMetaV2(authoringMeta, 2);
        assertEq(SUB_PARSER_PARSE_META, expected);
    }

    /// #63 — committed BYTECODE_HASH is verified against the actual compiled contract
    /// so any bytecode drift (optimizer change, solc bump, library edit) fires CI red.
    function testBytecodeHash() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertEq(address(flareFtsoWords).codehash, BYTECODE_HASH, "BYTECODE_HASH drifted from compiled bytecode");
    }

    /// #64 — both index-constant sets must agree element-for-element; any reorder
    /// in either file that breaks the pairing is caught without a fork or RPC.
    function testWordOpcodeIndicesAligned() external pure {
        assertEq(SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD, OPCODE_FTSO_CURRENT_PRICE_USD);
        assertEq(SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR, OPCODE_FTSO_CURRENT_PRICE_PAIR);
        assertEq(SUB_PARSER_WORD_SFLR_EXCHANGE_RATE, OPCODE_SFLR_CURRENT_EXCHANGE_RATE);
        assertEq(SUB_PARSER_WORD_PARSERS_LENGTH, OPCODE_FUNCTION_POINTERS_LENGTH);

        bytes memory authoringMetaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory meta = abi.decode(authoringMetaBytes, (AuthoringMetaV2[]));
        assertEq(meta[OPCODE_FTSO_CURRENT_PRICE_USD].word, bytes32("ftso-current-price-usd"));
        assertEq(meta[OPCODE_FTSO_CURRENT_PRICE_PAIR].word, bytes32("ftso-current-price-pair"));
        assertEq(meta[OPCODE_SFLR_CURRENT_EXCHANGE_RATE].word, bytes32("sflr-exchange-rate"));
    }
}
