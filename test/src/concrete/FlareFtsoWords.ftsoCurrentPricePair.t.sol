// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest, StackItem} from "rainlang-0.2.6/src/../test/abstract/OpTest.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {Strings} from "@openzeppelin-contracts-5.6.1/utils/Strings.sol";
import {BLOCK_NUMBER} from "../lib/registry/LibFlareContractRegistry.t.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.2.1/src/lib/LibDecimalFloat.sol";

contract FlareFtsoWordsFtsoCurrentPricePairTest is OpTest {
    using Strings for address;

    function beforeOpTestConstructor() internal override {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testFlareFtsoWordsFtsoCurrentPricePairHappyFork() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        StackItem[] memory expectedStack = new StackItem[](1);
        expectedStack[0] = StackItem.wrap(
            Float.unwrap(
                LibDecimalFloat.packLossless(2780193435782859109269589980156436027045273051983740074270490015516, -68)
            )
        );

        checkHappy(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(flareFtsoWords).toHexString(),
                    " _: ftso-current-price-pair(\"ETH\" \"BTC\" 3600);"
                )
            ),
            expectedStack,
            "ftso-current-price-pair(\"ETH\" \"BTC\" 3600)"
        );
    }

    function testFlareFtsoWordsFtsoCurrentPricePairHappyPrecisionFork() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        StackItem[] memory expectedStack = new StackItem[](1);
        expectedStack[0] = StackItem.wrap(
            Float.unwrap(
                LibDecimalFloat.packLossless(7471283741695112996296236583567719364072468887361328723293549999340, -72)
            )
        );

        checkHappy(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(flareFtsoWords).toHexString(),
                    " _: ftso-current-price-pair(\"FLR\" \"ETH\" 3600);"
                )
            ),
            expectedStack,
            "ftso-current-price-pair(\"FLR\" \"ETH\" 3600)"
        );

        expectedStack[0] = StackItem.wrap(
            Float.unwrap(
                LibDecimalFloat.packLossless(13384580676802354095144678764100049043648847474252084355076017655713, -62)
            )
        );
        checkHappy(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(flareFtsoWords).toHexString(),
                    " _: ftso-current-price-pair(\"ETH\" \"FLR\" 3600);"
                )
            ),
            expectedStack,
            "ftso-current-price-pair(\"ETH\" \"FLR\" 3600)"
        );
    }
}
