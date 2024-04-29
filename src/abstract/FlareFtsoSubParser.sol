// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {BaseRainterpreterSubParserNPE2, Operand} from "rain.interpreter/abstract/BaseRainterpreterSubParserNPE2.sol";
import {OPCODE_FTSO_CURRENT_PRICE_USD, OPCODE_FTSO_CURRENT_PRICE_PAIR} from "./FlareFtsoExtern.sol";
import {LibSubParse, IInterpreterExternV3} from "rain.interpreter/lib/parse/LibSubParse.sol";
import {LibParseOperand} from "rain.interpreter/lib/parse/LibParseOperand.sol";
import {LibConvert} from "rain.lib.typecast/LibConvert.sol";
import {AuthoringMetaV2} from "rain.interpreter.interface/interface/IParserV1.sol";

/// @dev Runtime constant form of the parse meta. Used to map stringy words into
/// indexes in roughly O(1).
bytes constant SUB_PARSER_PARSE_META =
    hex"01000002000000000000000000000000000000000000080000000000000000000000008057ab015dba81";

/// @dev Runtime constant form of the pointers to the word parsers.
bytes constant SUB_PARSER_WORD_PARSERS = hex"07a207c4";

/// @dev Runtime constant form of the pointers to the operand handlers.
bytes constant SUB_PARSER_OPERAND_HANDLERS = hex"0c7d0c7d";

/// @dev Index into the function pointers array for the current USD price.
uint256 constant SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD = 0;
/// @dev Index into the function pointers array for the current pair price.
uint256 constant SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR = 1;
/// @dev The number of function pointers in the array.
uint256 constant SUB_PARSER_WORD_PARSERS_LENGTH = 2;

/// Builds the authoring meta for the sub parser. This is used both as data for
/// tooling directly, and to build the runtime parse meta.
//slither-disable-next-line dead-code
function authoringMetaV2() pure returns (bytes memory) {
    AuthoringMetaV2[] memory meta = new AuthoringMetaV2[](SUB_PARSER_WORD_PARSERS_LENGTH);
    meta[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD] = AuthoringMetaV2(
        "ftso-current-price-usd",
        "Returns the current USD price of the given token according to the FTSO. Accepts 2 inputs, the symbol string used by the FTSO and the timeout in seconds. The price is returned as 18 decimal fixed point number, rounding down if this results in any precision loss. The timeout will be used to determine if the price is stale and revert if it is."
    );
    meta[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR] = AuthoringMetaV2(
        "ftso-current-price-pair",
        "Returns the current price of the given token pair according to the FTSO. Accepts 3 inputs, the symbol string used by the FTSO for the base token, the symbol string used by the FTSO for the quote token and the timeout in seconds. The price is returned as 18 decimal fixed point number, rounding down if this results in any precision loss. The timeout will be used to determine if the price is stale and revert if it is. Note that the pair price is derived from two separate FTSO prices mechanically and is not provided directly by the FTSO."
    );
    return abi.encode(meta);
}

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
    function buildSubParserOperandHandlers() external pure returns (bytes memory) {
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
