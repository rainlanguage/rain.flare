// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFlareFtsoSubParser, SUB_PARSER_WORD_PARSERS_LENGTH} from "src/lib/parse/LibFlareFtsoSubParser.sol";
import {AuthoringMetaV2} from "rain-interpreter-interface-0.1.0/src/interface/deprecated/v1/IParserV1.sol";

contract LibFlareFtsoSubParserAuthoringMetaTest is Test {
    function testAuthoringMetaV2Length() external pure {
        bytes memory metaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory meta = abi.decode(metaBytes, (AuthoringMetaV2[]));
        assertEq(meta.length, SUB_PARSER_WORD_PARSERS_LENGTH, "meta length must equal SUB_PARSER_WORD_PARSERS_LENGTH");
    }

    function testAuthoringMetaV2WordNames() external pure {
        bytes memory metaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory meta = abi.decode(metaBytes, (AuthoringMetaV2[]));
        assertEq(meta[0].word, "ftso-current-price-usd", "index 0 must be ftso-current-price-usd");
        assertEq(meta[1].word, "ftso-current-price-pair", "index 1 must be ftso-current-price-pair");
        assertEq(meta[2].word, "sflr-exchange-rate", "index 2 must be sflr-exchange-rate");
    }

    function testAuthoringMetaV2DescriptionsNonEmpty() external pure {
        bytes memory metaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory meta = abi.decode(metaBytes, (AuthoringMetaV2[]));
        assertTrue(bytes(meta[0].description).length > 0, "ftso-current-price-usd description must be non-empty");
        assertTrue(bytes(meta[1].description).length > 0, "ftso-current-price-pair description must be non-empty");
        assertTrue(bytes(meta[2].description).length > 0, "sflr-exchange-rate description must be non-empty");
    }

    function testAuthoringMetaV2UsdInputCount() external pure {
        bytes memory metaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory meta = abi.decode(metaBytes, (AuthoringMetaV2[]));
        assertTrue(
            _containsSubstring(meta[0].description, "2 input"),
            "ftso-current-price-usd description must mention 2 inputs"
        );
    }

    function testAuthoringMetaV2PairInputCount() external pure {
        bytes memory metaBytes = LibFlareFtsoSubParser.authoringMetaV2();
        AuthoringMetaV2[] memory meta = abi.decode(metaBytes, (AuthoringMetaV2[]));
        assertTrue(
            _containsSubstring(meta[1].description, "3 input"),
            "ftso-current-price-pair description must mention 3 inputs"
        );
    }

    function _containsSubstring(string memory haystack, string memory needle) private pure returns (bool) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length > h.length) return false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        return false;
    }
}
