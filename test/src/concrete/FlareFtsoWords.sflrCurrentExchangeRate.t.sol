// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {OpTest} from "rain.interpreter.interface/../test/abstract/OpTest.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

uint256 constant BLOCK_NUMBER = 29599077;

contract FlareSflrCurrentExchangeRateTest is OpTest {
    using Strings for address;

    function beforeOpTestConstructor() internal override {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testFlareFtsoWordsFtsoCurrentPricePairHappyFork() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        uint256[] memory expectedStack = new uint256[](1);
        expectedStack[0] = 0.910960240479513941e18;

        checkHappy(
            bytes(
                string.concat("using-words-from ", address(flareFtsoWords).toHexString(), " _: sflr-exchange-rate();")
            ),
            expectedStack,
            "sflr-exchange-rate()"
        );
    }
}
