// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
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
import {DESCRIBED_BY_META_HASH} from "../generated/FlareFtsoWords.pointers.sol";
import {IDescribedByMetaV1} from "rain.metadata/interface/IDescribedByMetaV1.sol";

/// @title FlareFtsoWords
/// Simply merges the two abstract contracts into a single concrete contract.
contract FlareFtsoWords is FlareFtsoExtern, FlareFtsoSubParser {
    /// @inheritdoc IDescribedByMetaV1
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
