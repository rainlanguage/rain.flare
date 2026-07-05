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
import {
    LibFlareFtsoSubParser,
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD,
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR,
    SUB_PARSER_WORD_SFLR_EXCHANGE_RATE,
    SUB_PARSER_WORD_PARSERS_LENGTH
} from "src/lib/parse/LibFlareFtsoSubParser.sol";
import {OPCODE_FUNCTION_POINTERS_LENGTH} from "src/abstract/FlareFtsoExtern.sol";
import {BYTECODE_HASH} from "src/generated/FlareFtsoWords.pointers.sol";

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

    function testAuthoringMetaV2Content() external pure {
        bytes memory authoringMetaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory authoringMeta = abi.decode(authoringMetaBytes, (AuthoringMetaV2[]));
        assertEq(authoringMeta.length, 3);
        assertEq(authoringMeta[0].word, bytes32("ftso-current-price-usd"));
        assertEq(
            authoringMeta[0].description,
            "Returns the current USD price of the given token according to the FTSO. Accepts 2 inputs, the symbol string used by the FTSO and the timeout in seconds. The price is rounded down if it does not fit in a Rainlang number. The timeout will be used to determine if the price is stale and revert if it is."
        );
        assertEq(authoringMeta[1].word, bytes32("ftso-current-price-pair"));
        assertEq(
            authoringMeta[1].description,
            "Returns the current price of the given token pair according to the FTSO. Accepts 3 inputs, the symbol string used by the FTSO for the base token, the symbol string used by the FTSO for the quote token and the timeout in seconds. The price is rounded down if it does not fit in a Rainlang number. The timeout will be used to determine if the price is stale and revert if it is. Note that the pair price is derived from two separate FTSO prices mechanically and is not provided directly by the FTSO."
        );
        assertEq(authoringMeta[2].word, bytes32("sflr-exchange-rate"));
        assertEq(authoringMeta[2].description, "Returns the current exchange rate of FLR to SFLR.");
    }

    function testOpcodePointersLength() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertEq(flareFtsoWords.buildOpcodeFunctionPointers().length, OPCODE_FUNCTION_POINTERS_LENGTH * 2);
        assertEq(flareFtsoWords.buildIntegrityFunctionPointers().length, OPCODE_FUNCTION_POINTERS_LENGTH * 2);
    }

    function testAuthoringMetaContent() external pure {
        AuthoringMetaV2[] memory m = abi.decode(LibFlareFtsoSubParser.authoringMetaV2(), (AuthoringMetaV2[]));
        assertEq(m.length, SUB_PARSER_WORD_PARSERS_LENGTH);
        assertEq(m[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD].word, bytes32("ftso-current-price-usd"));
        assertEq(m[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR].word, bytes32("ftso-current-price-pair"));
        assertEq(m[SUB_PARSER_WORD_SFLR_EXCHANGE_RATE].word, bytes32("sflr-exchange-rate"));
        assertTrue(bytes(m[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD].description).length > 0);
        assertTrue(bytes(m[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR].description).length > 0);
        assertTrue(bytes(m[SUB_PARSER_WORD_SFLR_EXCHANGE_RATE].description).length > 0);
    }

    function testBytecodeHashMatchesDeployedCode() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertEq(address(flareFtsoWords).codehash, BYTECODE_HASH, "BYTECODE_HASH is stale");
    }
}
