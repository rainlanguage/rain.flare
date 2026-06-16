// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {
    BaseRainlangSubParser,
    OperandV2,
    IParserToolingV1,
    ISubParserToolingV1
} from "rainlang-0.1.2/src/abstract/BaseRainlangSubParser.sol";
import {
    OPCODE_FTSO_CURRENT_PRICE_USD,
    OPCODE_FTSO_CURRENT_PRICE_PAIR,
    OPCODE_SLFR_CURRENT_EXCHANGE_RATE
} from "./FlareFtsoExtern.sol";
import {LibSubParse, IInterpreterExternV4} from "rainlang-0.1.2/src/lib/parse/LibSubParse.sol";
import {LibParseOperand} from "rainlang-0.1.2/src/lib/parse/LibParseOperand.sol";
import {LibConvert} from "rain-lib-typecast-0.1.0/src/LibConvert.sol";
//Export this for convenience.
//forge-lint: disable-next-line(mixed-case-function,unused-import)
import {AuthoringMetaV2} from "rain-interpreter-interface-0.1.0/src/interface/deprecated/v1/IParserV1.sol";
import {
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD,
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR,
    SUB_PARSER_WORD_SFLR_EXCHANGE_RATE,
    SUB_PARSER_WORD_PARSERS_LENGTH
} from "../lib/parse/LibFlareFtsoSubParser.sol";
import {
    OPERAND_HANDLER_FUNCTION_POINTERS as SUB_PARSER_OPERAND_HANDLERS,
    SUB_PARSER_WORD_PARSERS,
    PARSE_META as SUB_PARSER_PARSE_META,
    PARSE_META_BUILD_DEPTH
} from "../generated/FlareFtsoWords.pointers.sol";

/// @title FlareFtsoSubParser
/// Implements the sub parser half of FlareFtsoWords. Responsible for parsing
/// the words and operands that are used by the FlareFtsoWords. Provides the
/// sugar required to make the externs work like native rain words.
abstract contract FlareFtsoSubParser is BaseRainlangSubParser {
    /// Allows the FlareFtsoWords contract to feed the extern address (itself)
    /// into the sub parser functions by overriding `extern`.
    function extern() internal view virtual returns (address);

    /// @inheritdoc BaseRainlangSubParser
    function subParserParseMeta() internal pure override returns (bytes memory) {
        return SUB_PARSER_PARSE_META;
    }

    /// @inheritdoc BaseRainlangSubParser
    function subParserWordParsers() internal pure override returns (bytes memory) {
        return SUB_PARSER_WORD_PARSERS;
    }

    /// @inheritdoc BaseRainlangSubParser
    function subParserOperandHandlers() internal pure override returns (bytes memory) {
        return SUB_PARSER_OPERAND_HANDLERS;
    }

    /// Create a 16-bit pointer array for the operand handlers. This is
    /// relatively gas inefficent so it is only called during tests to cross
    /// reference against the constant values that are used at runtime.
    /// @inheritdoc IParserToolingV1
    function buildOperandHandlerFunctionPointers() external pure returns (bytes memory) {
        function(bytes32[] memory) internal pure returns (OperandV2)[] memory fs =
            new function(bytes32[] memory) internal pure returns (OperandV2)[](SUB_PARSER_WORD_PARSERS_LENGTH);
        fs[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD] = LibParseOperand.handleOperandDisallowed;
        fs[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR] = LibParseOperand.handleOperandDisallowed;
        fs[SUB_PARSER_WORD_SFLR_EXCHANGE_RATE] = LibParseOperand.handleOperandDisallowed;

        uint256[] memory pointers;
        assembly ("memory-safe") {
            pointers := fs
        }
        return LibConvert.unsafeTo16BitBytes(pointers);
    }

    /// @inheritdoc IParserToolingV1
    function buildLiteralParserFunctionPointers() external pure returns (bytes memory) {
        return "";
    }

    /// Create a 16-bit pointer array for the word parsers. This is relatively
    /// gas inefficent so it is only called during tests to cross reference
    /// against the constant values that are used at runtime.
    /// @inheritdoc ISubParserToolingV1
    function buildSubParserWordParsers() external pure returns (bytes memory) {
        function(uint256, uint256, OperandV2) internal view returns (bool, bytes memory, bytes32[] memory)[] memory fs = new function(uint256, uint256, OperandV2)
        internal
        view returns (bool, bytes memory, bytes32[] memory)[](SUB_PARSER_WORD_PARSERS_LENGTH);
        fs[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD] = ftsoCurrentPriceUsdSubParser;
        fs[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR] = ftsoCurrentPricePairSubParser;
        fs[SUB_PARSER_WORD_SFLR_EXCHANGE_RATE] = sFlrCurrentExchangeRateSubParser;

        uint256[] memory pointers;
        assembly ("memory-safe") {
            pointers := fs
        }
        return LibConvert.unsafeTo16BitBytes(pointers);
    }

    /// Thin wrapper around LibSubParse.subParserExtern that provides the extern
    /// address and index of the current usd price opcode index in the extern.
    //slither-disable-next-line dead-code
    function ftsoCurrentPriceUsdSubParser(uint256 constantsHeight, uint256 ioByte, OperandV2 operand)
        internal
        view
        returns (bool, bytes memory, bytes32[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserExtern(
            IInterpreterExternV4(extern()), constantsHeight, ioByte, operand, OPCODE_FTSO_CURRENT_PRICE_USD
        );
    }

    /// Thin wrapper around LibSubParse.subParserExtern that provides the extern
    /// address and index of the current pair price opcode index in the extern.
    //slither-disable-next-line dead-code
    function ftsoCurrentPricePairSubParser(uint256 constantsHeight, uint256 ioByte, OperandV2 operand)
        internal
        view
        returns (bool, bytes memory, bytes32[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserExtern(
            IInterpreterExternV4(extern()), constantsHeight, ioByte, operand, OPCODE_FTSO_CURRENT_PRICE_PAIR
        );
    }

    /// Thin wrapper around LibSubParse.subParserExtern that provides the extern
    /// address and index of the current pair price opcode index in the extern.
    //slither-disable-next-line dead-code
    function sFlrCurrentExchangeRateSubParser(uint256 constantsHeight, uint256 ioByte, OperandV2 operand)
        internal
        view
        returns (bool, bytes memory, bytes32[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserExtern(
            IInterpreterExternV4(extern()), constantsHeight, ioByte, operand, OPCODE_SLFR_CURRENT_EXCHANGE_RATE
        );
    }
}
