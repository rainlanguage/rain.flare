// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest} from "rainlang-0.1.2/src/../test/abstract/OpTest.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {Strings} from "@openzeppelin-contracts-5.6.1/utils/Strings.sol";
import {UnexpectedOperand} from "rainlang-0.1.2/src/error/ErrParse.sol";

contract FlareFtsoWordsOperandDisallowedTest is OpTest {
    using Strings for address;

    /// #54 — ftso-current-price-usd wires handleOperandDisallowed; explicit
    /// operand <0> must revert at parse time with UnexpectedOperand.
    function testFlareFtsoWordsOperandDisallowedUsd() external {
        FlareFtsoWords w = new FlareFtsoWords();
        checkUnhappyParse2(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(w).toHexString(),
                    " _: ftso-current-price-usd<0>(\"ETH\" 3600);"
                )
            ),
            abi.encodeWithSelector(UnexpectedOperand.selector)
        );
    }

    /// #54 — ftso-current-price-pair wires handleOperandDisallowed; explicit
    /// operand <0> must revert at parse time with UnexpectedOperand.
    function testFlareFtsoWordsOperandDisallowedPair() external {
        FlareFtsoWords w = new FlareFtsoWords();
        checkUnhappyParse2(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(w).toHexString(),
                    " _: ftso-current-price-pair<0>(\"BTC\" \"ETH\" 3600);"
                )
            ),
            abi.encodeWithSelector(UnexpectedOperand.selector)
        );
    }

    /// #54 — sflr-exchange-rate wires handleOperandDisallowed; explicit
    /// operand <0> must revert at parse time with UnexpectedOperand.
    function testFlareFtsoWordsOperandDisallowedSflr() external {
        FlareFtsoWords w = new FlareFtsoWords();
        checkUnhappyParse2(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(w).toHexString(),
                    " _: sflr-exchange-rate<0>();"
                )
            ),
            abi.encodeWithSelector(UnexpectedOperand.selector)
        );
    }
}
