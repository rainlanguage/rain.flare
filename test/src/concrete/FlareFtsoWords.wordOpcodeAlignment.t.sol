// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD,
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR,
    SUB_PARSER_WORD_SFLR_EXCHANGE_RATE,
    SUB_PARSER_WORD_PARSERS_LENGTH,
    LibFlareFtsoSubParser
} from "../../../src/lib/parse/LibFlareFtsoSubParser.sol";
import {
    OPCODE_FTSO_CURRENT_PRICE_USD,
    OPCODE_FTSO_CURRENT_PRICE_PAIR,
    OPCODE_SFLR_CURRENT_EXCHANGE_RATE,
    OPCODE_FUNCTION_POINTERS_LENGTH
} from "../../../src/abstract/FlareFtsoExtern.sol";
import {AuthoringMetaV2} from "rain-interpreter-interface-0.1.0/src/interface/deprecated/v1/IParserV1.sol";

contract FlareFtsoWordsWordOpcodeAlignmentTest is Test {
    function testWordOpcodeIndicesAligned() external pure {
        assertEq(SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD, OPCODE_FTSO_CURRENT_PRICE_USD);
        assertEq(SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR, OPCODE_FTSO_CURRENT_PRICE_PAIR);
        assertEq(SUB_PARSER_WORD_SFLR_EXCHANGE_RATE, OPCODE_SFLR_CURRENT_EXCHANGE_RATE);
        assertEq(SUB_PARSER_WORD_PARSERS_LENGTH, OPCODE_FUNCTION_POINTERS_LENGTH);
    }

    function testAuthoringMetaWordNamesMatchOpcodeSlots() external pure {
        AuthoringMetaV2[] memory m = abi.decode(LibFlareFtsoSubParser.authoringMetaV2(), (AuthoringMetaV2[]));
        assertEq(m[OPCODE_FTSO_CURRENT_PRICE_USD].word, bytes32("ftso-current-price-usd"));
        assertEq(m[OPCODE_FTSO_CURRENT_PRICE_PAIR].word, bytes32("ftso-current-price-pair"));
        assertEq(m[OPCODE_SFLR_CURRENT_EXCHANGE_RATE].word, bytes32("sflr-exchange-rate"));
    }
}
