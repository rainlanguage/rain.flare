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
        // Each description states the word's operand input count, which must
        // match the fixed arity enforced by that word's `integrity` function.
        // ftso-current-price-usd: integrity (2,1) => "2 input".
        assertTrue(
            contains(m[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD].description, "2 input"),
            "usd description input count does not match integrity arity (2,1)"
        );
        // ftso-current-price-pair: integrity (3,1) => "3 input".
        assertTrue(
            contains(m[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR].description, "3 input"),
            "pair description input count does not match integrity arity (3,1)"
        );
        // sflr-exchange-rate: integrity (0,1) => "0 input".
        assertTrue(
            contains(m[SUB_PARSER_WORD_SFLR_EXCHANGE_RATE].description, "0 input"),
            "sflr description input count does not match integrity arity (0,1)"
        );
    }

    /// @dev Minimal substring check as Solidity has no built-in for strings.
    /// Returns true iff `needle` occurs somewhere within `haystack`. The
    /// `needle.length > haystack.length` guard keeps the window comparison in
    /// bounds (and returns false, as a longer needle cannot be contained).
    function contains(string memory haystack, string memory needle) internal pure returns (bool) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length == 0) {
            return true;
        }
        if (n.length > h.length) {
            return false;
        }
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool matched = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    matched = false;
                    break;
                }
            }
            if (matched) {
                return true;
            }
        }
        return false;
    }

    function testBytecodeHashMatchesDeployedCode() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertEq(address(flareFtsoWords).codehash, BYTECODE_HASH, "BYTECODE_HASH is stale");
    }
}
