// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {BaseRainterpreterSubParserNPE2, Operand} from "rain.interpreter/abstract/BaseRainterpreterSubParserNPE2.sol";
import {OPCODE_FTSO_CURRENT_PRICE_USD, OPCODE_FTSO_CURRENT_PRICE_PAIR} from "./FlareFtsoExtern.sol";
import {LibSubParse, IInterpreterExternV3} from "rain.interpreter/lib/parse/LibSubParse.sol";
import {LibParseOperand} from "rain.interpreter/lib/parse/LibParseOperand.sol";
import {LibConvert} from "rain.lib.typecast/LibConvert.sol";
import {AuthoringMetaV2} from "rain.interpreter.interface/interface/deprecated/IParserV1.sol";
import {
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD,
    SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR,
    SUB_PARSER_WORD_PARSERS_LENGTH
} from "../lib/parse/LibFlareFtsoSubParser.sol";
import {
    OPERAND_HANDLER_FUNCTION_POINTERS as SUB_PARSER_OPERAND_HANDLERS,
    SUB_PARSER_WORD_PARSERS,
    PARSE_META as SUB_PARSER_PARSE_META
} from "../generated/FlareFtsoWords.pointers.sol";

uint8 constant PARSE_META_BUILD_DEPTH = 1;

/// @title FlareFtsoSubParser
/// Implements the sub parser half of FlareFtsoWords. Responsible for parsing
/// the words and operands that are used by the FlareFtsoWords. Provides the
/// sugar required to make the externs work like native rain words.
abstract contract FlareFtsoSubParser is BaseRainterpreterSubParserNPE2 {
    /// Allows the FlareFtsoWords contract to feed the extern address (itself)
    /// into the sub parser functions by overriding `extern`.
    function extern() internal view virtual returns (address);

    /// @inheritdoc BaseRainterpreterSubParserNPE2
    function subParserParseMeta() internal pure override returns (bytes memory) {
        return SUB_PARSER_PARSE_META;
    }

    /// @inheritdoc BaseRainterpreterSubParserNPE2
    function subParserWordParsers() internal pure override returns (bytes memory) {
        return SUB_PARSER_WORD_PARSERS;
    }

    /// @inheritdoc BaseRainterpreterSubParserNPE2
    function subParserOperandHandlers() internal pure override returns (bytes memory) {
        return SUB_PARSER_OPERAND_HANDLERS;
    }

    /// Create a 16-bit pointer array for the operand handlers. This is
    /// relatively gas inefficent so it is only called during tests to cross
    /// reference against the constant values that are used at runtime.
    function buildOperandHandlerFunctionPointers() external pure returns (bytes memory) {
        function(uint256[] memory) internal pure returns (Operand)[] memory fs =
            new function(uint256[] memory) internal pure returns (Operand)[](SUB_PARSER_WORD_PARSERS_LENGTH);
        fs[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD] = LibParseOperand.handleOperandDisallowed;
        fs[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR] = LibParseOperand.handleOperandDisallowed;

        uint256[] memory pointers;
        assembly ("memory-safe") {
            pointers := fs
        }
        return LibConvert.unsafeTo16BitBytes(pointers);
    }

    function buildLiteralParserFunctionPointers() external pure returns (bytes memory) {
        return "";
    }

    /// Create a 16-bit pointer array for the word parsers. This is relatively
    /// gas inefficent so it is only called during tests to cross reference
    /// against the constant values that are used at runtime.
    function buildSubParserWordParsers() external pure returns (bytes memory) {
        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[] memory fs =
        new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[](
            SUB_PARSER_WORD_PARSERS_LENGTH
        );
        fs[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD] = ftsoCurrentPriceUsdSubParser;
        fs[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR] = ftsoCurrentPricePairSubParser;

        uint256[] memory pointers;
        assembly ("memory-safe") {
            pointers := fs
        }
        return LibConvert.unsafeTo16BitBytes(pointers);
    }

    /// Thin wrapper around LibSubParse.subParserExtern that provides the extern
    /// address and index of the current usd price opcode index in the extern.
    //slither-disable-next-line dead-code
    function ftsoCurrentPriceUsdSubParser(uint256 constantsHeight, uint256 ioByte, Operand operand)
        internal
        view
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserExtern(
            IInterpreterExternV3(extern()), constantsHeight, ioByte, operand, OPCODE_FTSO_CURRENT_PRICE_USD
        );
    }

    /// Thin wrapper around LibSubParse.subParserExtern that provides the extern
    /// address and index of the current pair price opcode index in the extern.
    //slither-disable-next-line dead-code
    function ftsoCurrentPricePairSubParser(uint256 constantsHeight, uint256 ioByte, Operand operand)
        internal
        view
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserExtern(
            IInterpreterExternV3(extern()), constantsHeight, ioByte, operand, OPCODE_FTSO_CURRENT_PRICE_PAIR
        );
    }
}
