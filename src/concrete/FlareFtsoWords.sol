// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {
    FlareFtsoExtern,
    OPCODE_FUNCTION_POINTERS,
    INTEGRITY_FUNCTION_POINTERS,
    BaseRainterpreterExternNPE2
} from "../abstract/FlareFtsoExtern.sol";
import {
    FlareFtsoSubParser,
    SUB_PARSER_WORD_PARSERS,
    SUB_PARSER_OPERAND_HANDLERS,
    SUB_PARSER_PARSE_META,
    BaseRainterpreterSubParserNPE2,
    AuthoringMetaV2
} from "../abstract/FlareFtsoSubParser.sol";

bytes32 constant DESCRIBED_BY_META_HASH = bytes32(0x24ede5b126d4acfe8f5ba9975cb027f07568798a6ddd681f0e2f23be5b5bd7bc);

/// @title FlareFtsoWords
/// Simply merges the two abstract contracts into a single concrete contract.
contract FlareFtsoWords is FlareFtsoExtern, FlareFtsoSubParser {
    function describedByMetaV1() external pure returns (bytes32) {
        return DESCRIBED_BY_META_HASH;
    }

    /// @inheritdoc FlareFtsoSubParser
    //slither-disable-next-line dead-code
    function extern() internal view override returns (address) {
        return address(this);
    }

    /// This is only needed because the parser and extern base contracts both
    /// implement IERC165, and the compiler needs to be told how to resolve the
    /// ambiguity.
    /// @inheritdoc BaseRainterpreterSubParserNPE2
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseRainterpreterSubParserNPE2, BaseRainterpreterExternNPE2)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
