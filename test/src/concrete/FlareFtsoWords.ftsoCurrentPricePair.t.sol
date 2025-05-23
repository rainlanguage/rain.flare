// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest} from "rain.interpreter/../test/abstract/OpTest.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {BLOCK_NUMBER} from "../lib/registry/LibFlareContractRegistry.t.sol";

contract FlareFtsoWordsFtsoCurrentPricePairTest is OpTest {
    using Strings for address;

    function beforeOpTestConstructor() internal override {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testFlareFtsoWordsFtsoCurrentPricePairHappyFork() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        uint256[] memory expectedStack = new uint256[](1);
        expectedStack[0] = 0.037311198493953294e18;

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

        uint256[] memory expectedStack = new uint256[](1);
        expectedStack[0] = 0.000005630014253715e18;

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

        expectedStack[0] = 177619.443741209563994374e18;
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
