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
}
