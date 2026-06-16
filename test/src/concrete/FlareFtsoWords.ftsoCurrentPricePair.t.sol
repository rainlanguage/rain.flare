// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest, StackItem} from "rainlang-0.1.2/src/../test/abstract/OpTest.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {Strings} from "@openzeppelin-contracts-5.6.1/utils/Strings.sol";
import {BLOCK_NUMBER} from "test/fork/ForkConstants.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

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
                LibDecimalFloat.packLossless(
                    0.03731119849395329429139187416029293517999955454915312408433138156716e68, -68
                )
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
                LibDecimalFloat.packLossless(
                    0.000005630014253715341229403249093895330805483328231149412663808026269472e72, -72
                )
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
                LibDecimalFloat.packLossless(
                    177619.4437412095639943741209563994374120956399437412095639943741209e61, -61
                )
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
