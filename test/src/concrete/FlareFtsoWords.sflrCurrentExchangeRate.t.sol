// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest, StackItem} from "rainlang-0.1.2/src/../test/abstract/OpTest.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {Strings} from "@openzeppelin-contracts-5.6.1/utils/Strings.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {BLOCK_NUMBER} from "test/fork/ForkConstants.sol";

contract FlareSflrCurrentExchangeRateTest is OpTest {
    using Strings for address;

    function beforeOpTestConstructor() internal override {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testFlareFtsoWordsFtsoCurrentExchangeRateHappyFork() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        StackItem[] memory expectedStack = new StackItem[](1);
        expectedStack[0] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(0.877817288626455057e18, -18)));

        checkHappy(
            bytes(
                string.concat("using-words-from ", address(flareFtsoWords).toHexString(), " _: sflr-exchange-rate();")
            ),
            expectedStack,
            "sflr-exchange-rate()"
        );
    }
}
