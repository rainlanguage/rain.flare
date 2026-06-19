// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {
    FlareFtsoExtern,

    //forge-lint: disable-next-line(unused-import)
    OPCODE_FUNCTION_POINTERS,

    //forge-lint: disable-next-line(unused-import)
    INTEGRITY_FUNCTION_POINTERS,
    BaseRainlangExtern
} from "../abstract/FlareFtsoExtern.sol";
import {
    FlareFtsoSubParser,

    //forge-lint: disable-next-line(unused-import)
    SUB_PARSER_WORD_PARSERS,

    //forge-lint: disable-next-line(unused-import)
    SUB_PARSER_OPERAND_HANDLERS,

    //forge-lint: disable-next-line(unused-import)
    SUB_PARSER_PARSE_META,
    BaseRainlangSubParser,

    //forge-lint: disable-next-line(unused-import)
    AuthoringMetaV2
} from "../abstract/FlareFtsoSubParser.sol";
import {
    DESCRIBED_BY_META_HASH,

    //forge-lint: disable-next-line(unused-import)
    BYTECODE_HASH
} from "../generated/FlareFtsoWords.pointers.sol";
import {IDescribedByMetaV1} from "rain-metadata-0.1.0/src/interface/IDescribedByMetaV1.sol";

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
    /// @inheritdoc BaseRainlangSubParser
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseRainlangSubParser, BaseRainlangExtern)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
